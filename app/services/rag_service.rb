require 'json'

class RagService
  CHUNK_SIZE = 1000
  CHUNK_OVERLAP = 200

  def self.ask_question(question, blog_ids = [])
    service = new
    service.ask_question(question, blog_ids)
  end

  def ask_question(question, blog_ids = [])
    articles = if blog_ids.present?
      Blog.where(id: blog_ids).published
    else
      Blog.published
    end

    return error_response("No articles found") if articles.empty?

    relevant_chunks = retrieve_relevant_chunks(question, articles)

    return error_response("No relevant content found") if relevant_chunks.empty?

    answer = generate_answer(question, relevant_chunks)

    success_response(answer, relevant_chunks)
  rescue => e
    Rails.logger.error "RAG Error: #{e.message}"
    error_response("Failed to generate answer: #{e.message}")
  end

  private

  def chunk_article(article)
    chunks = []
    content = "#{article.title}\n\n#{article.content}"
    words = content.split(/\s+/)

    current_chunk = []
    current_length = 0

    words.each do |word|
      word_length = word.length + 1 # +1 for space

      if current_length + word_length > CHUNK_SIZE && current_chunk.any?
        chunk_text = current_chunk.join(' ')
        chunks << {
          text: chunk_text,
          article_id: article.id,
          article_title: article.title
        }

        overlap_words = current_chunk.last([CHUNK_OVERLAP / 10, current_chunk.length].min)
        current_chunk = overlap_words
        current_length = overlap_words.join(' ').length
      end

      current_chunk << word
      current_length += word_length
    end

    if current_chunk.any?
      chunks << {
        text: current_chunk.join(' '),
        article_id: article.id,
        article_title: article.title
      }
    end

    chunks
  end

  def retrieve_relevant_chunks(question, articles, top_k = 5)
    question_embedding_json = EmbeddingService.generate_embedding(question)
    return [] if question_embedding_json.nil?

    question_vector = JSON.parse(question_embedding_json)

    all_chunks = []
    articles.each do |article|
      article_chunks = chunk_article(article)
      all_chunks.concat(article_chunks)
    end

    Rails.logger.info "Total chunks to search: #{all_chunks.length}"

    chunk_similarities = []

    all_chunks.each do |chunk|
      chunk_embedding_json = EmbeddingService.generate_embedding(chunk[:text])
      next if chunk_embedding_json.nil?

      chunk_vector = JSON.parse(chunk_embedding_json)

      similarity = EmbeddingService.cosine_similarity(question_vector, chunk_vector)

      chunk_similarities << {
        chunk: chunk,
        similarity: similarity
      }
    end

    relevant = chunk_similarities
      .sort_by { |cs| -cs[:similarity] }
      .take(top_k)
      .map do |cs|
        {
          text: cs[:chunk][:text],
          article_id: cs[:chunk][:article_id],
          article_title: cs[:chunk][:article_title],
          similarity: cs[:similarity].round(4)
        }
      end

    Rails.logger.info "Retrieved #{relevant.length} relevant chunks"
    relevant.each_with_index do |chunk, i|
      Rails.logger.info "  #{i + 1}. #{chunk[:article_title]} (similarity: #{chunk[:similarity]})"
    end

    relevant
  end

  def generate_answer(question, relevant_chunks)
    context = relevant_chunks.map.with_index do |chunk, i|
      "[Source #{i + 1}: #{chunk[:article_title]}]\n#{chunk[:text]}"
    end.join("\n\n---\n\n")

    prompt = build_rag_prompt(question, context)

    response = HTTParty.post(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
      query: { key: Rails.application.config.gemini_api_key },
      headers: { 'Content-Type' => 'application/json' },
      body: {
        contents: [{
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.3, # Lower temperature for factual answers
          maxOutputTokens: 1024
        }
      }.to_json
    )

    if response.success?
      answer_text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
      answer_text&.strip || "I couldn't generate an answer."
    else
      Rails.logger.error "Gemini API error: #{response.body}"
      "Failed to generate answer from AI."
    end
  end

  def build_rag_prompt(question, context)
    <<~PROMPT
      You are a helpful programming assistant. Answer the question based ONLY on the provided context from programming articles.

      Context (from retrieved articles):

      Question: #{question}

      Instructions:
      1. Answer the question using information from the context above
      2. If the context doesn't contain enough information, say "Based on the provided articles, I don't have enough information to answer this question fully."
      3. Cite which source(s) you used (e.g., "According to Source 1...")
      4. Be concise but thorough
      5. Use code examples from the context if relevant
      6. DO NOT make up information not in the context

      Answer:
    PROMPT
  end

  def success_response(answer, chunks)
    {
      success: true,
      answer: answer,
      sources: chunks.map do |chunk|
        {
          article_id: chunk[:article_id],
          article_title: chunk[:article_title],
          similarity: chunk[:similarity],
          excerpt: chunk[:text][0..200] + "..."
        }
      end
    }
  end

  def error_response(message)
    {
      success: false,
      error: message,
      answer: nil,
      sources: []
    }
  end
end
