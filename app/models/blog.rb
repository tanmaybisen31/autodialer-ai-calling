class Blog < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  scope :published, -> { where.not(published_at: nil).order(published_at: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  after_save :generate_embedding_async, if: :should_generate_embedding?

  def published?
    published_at.present?
  end

  def tags_array
    tags.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def tags_array=(arr)
    self.tags = arr.join(', ')
  end

  def generate_embedding!
    text_for_embedding = "#{title}\n\n#{content}\n\nTags: #{tags}"
    embedding_json = EmbeddingService.generate_embedding(text_for_embedding)

    if embedding_json.present?
      update_column(:embedding, embedding_json)
      Rails.logger.info "Generated embedding for blog ##{id}: #{title}"
    else
      Rails.logger.warn "Failed to generate embedding for blog ##{id}"
    end
  end

  def self.similar_to(query_text, limit: 5, min_similarity: 0.5)
    return [] if query_text.blank?

    query_embedding_json = EmbeddingService.generate_embedding(query_text)

    if query_embedding_json.nil?
      Rails.logger.warn "Semantic search fallback: query embedding missing for '#{query_text}'"
      return keyword_search(query_text, limit: limit)
    end

    begin
      query_vector = JSON.parse(query_embedding_json)
    rescue JSON::ParserError => e
      Rails.logger.error "Error parsing query embedding JSON: #{e.message}"
      return keyword_search(query_text, limit: limit)
    end

    similarities = []

    published.where.not(embedding: nil).find_each do |article|
      next if article.embedding.blank?

      begin
        stored_vector = JSON.parse(article.embedding)
      rescue JSON::ParserError => e
        Rails.logger.warn "Skipping blog ##{article.id} during semantic search due to invalid embedding JSON: #{e.message}"
        next
      end

      similarity = EmbeddingService.cosine_similarity(query_vector, stored_vector)

      similarities << {
        article: article,
        similarity: similarity
      }
    end

    ranked_results = similarities
      .select { |s| s[:similarity] >= min_similarity }
      .sort_by { |s| -s[:similarity] }
      .take(limit)
      .map { |s| { article: s[:article], score: s[:similarity].round(4) } }

    return ranked_results if ranked_results.size >= limit

    fallback_results = keyword_search(query_text, limit: limit * 2)

    fallback_results.each do |fallback|
      next if ranked_results.any? { |existing| existing[:article].id == fallback[:article].id }

      ranked_results << fallback
      break if ranked_results.size >= limit
    end

    ranked_results.presence || fallback_results.take(limit)
  end

  def find_related_articles(limit: 5)
    return [] if embedding.blank?

    query_text = "#{title}\n\n#{content}"
    related = self.class.similar_to(query_text, limit: limit + 1)

    related.reject { |r| r[:article].id == id }.take(limit)
  end

  def self.semantic_search(query, limit: 10, min_similarity: 0.3)
    similar_to(query, limit: limit, min_similarity: min_similarity)
  end

  private

  def self.keyword_search(query_text, limit:)
    return [] if query_text.blank?

    sanitized = sanitize_sql_like(query_text.to_s.downcase)
    pattern = "%#{sanitized}%"

    fallback_articles = published.where(
      "LOWER(title) LIKE :pattern OR LOWER(tags) LIKE :pattern OR LOWER(content) LIKE :pattern",
      pattern: pattern
    ).limit(limit)

    fallback_articles.map { |article| { article: article, score: nil } }
  end

  def should_generate_embedding?
    (saved_change_to_title? || saved_change_to_content? || saved_change_to_tags?) &&
    published?
  end

  def generate_embedding_async
    generate_embedding! if embedding.blank?
  end
end
