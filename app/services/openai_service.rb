require 'httparty'

class OpenaiService
  include HTTParty
  base_uri 'https://api.openai.com/v1'

  attr_reader :api_key

  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    raise "OPENAI_API_KEY environment variable not set" if @api_key.blank?
  end

  def self.generate_articles_from_prompt(user_prompt)
    service = new
    service.parse_and_generate_articles(user_prompt)
  end

  def parse_and_generate_articles(user_prompt)
    parsed_articles = parse_article_specifications(user_prompt)

    return { success: false, error: "Could not parse article specifications" } unless parsed_articles[:success]

    articles = []
    errors = []

    parsed_articles[:articles].each do |spec|
      begin
        content = generate_blog_article(
          title: spec['title'],
          description: spec['description'],
          tags: spec['tags']
        )

        articles << {
          title: spec['title'],
          content: content,
          tags: spec['tags'],
          description: spec['description']
        }
      rescue => e
        errors << { title: spec['title'], error: e.message }
      end
    end

    {
      success: true,
      articles: articles,
      errors: errors,
      count: articles.size
    }
  end

  def parse_article_specifications(user_prompt)
    prompt = <<~PROMPT
      Parse the following user input which contains blog article titles and details.
      Extract each article's title, optional description/context, and optional tags.

      User input:

      Respond ONLY with valid JSON in this exact format:
      {
        "articles": [
          {
            "title": "Article Title",
            "description": "Optional description or context",
            "tags": "comma, separated, tags"
          }
        ]
      }

      Rules:
      - Extract all article titles from the input
      - Include any descriptions or context provided
      - Infer relevant tags if not explicitly provided
      - If no description is given, use null
      - If no tags are given, infer appropriate programming-related tags
    PROMPT

    response = self.class.post(
      '/chat/completions',
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{api_key}"
      },
      body: {
        model: 'gpt-4o-mini',
        messages: [
          { role: 'user', content: prompt }
        ],
        temperature: 0.3,
        max_tokens: 1000,
        response_format: { type: 'json_object' }
      }.to_json
    )

    if response.success?
      content = response.dig('choices', 0, 'message', 'content')
      parsed = JSON.parse(content)
      { success: true, articles: parsed['articles'] || [] }
    else
      Rails.logger.error "OpenAI API error: #{response.body}"
      { success: false, error: response.body }
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse JSON from OpenAI: #{e.message}"
    { success: false, error: "Could not parse AI response" }
  rescue => e
    Rails.logger.error "Error parsing article specifications: #{e.message}"
    { success: false, error: e.message }
  end

  def generate_blog_article(title:, description: nil, tags: nil)
    prompt = build_article_prompt(title: title, description: description, tags: tags)

    response = self.class.post(
      '/chat/completions',
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{api_key}"
      },
      body: {
        model: 'gpt-4o-mini',
        messages: [
          { role: 'user', content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 2500
      }.to_json
    )

    if response.success?
      content = response.dig('choices', 0, 'message', 'content')
      content&.strip || "Article content could not be generated."
    else
      Rails.logger.error "OpenAI API error: #{response.body}"
      raise "Failed to generate article: #{response.body}"
    end
  rescue => e
    Rails.logger.error "Article generation error: #{e.message}"
    raise "Error generating article: #{e.message}"
  end

  private

  def build_article_prompt(title:, description: nil, tags: nil)
    prompt = <<~PROMPT
      Write a comprehensive, well-structured programming blog article with the following details:

      Title: #{title}
    PROMPT

    prompt += "\nDescription/Context: #{description}" if description.present?
    prompt += "\nTags/Topics: #{tags.is_a?(Array) ? tags.join(', ') : tags}" if tags.present?

    prompt += <<~ADDITIONAL

      Requirements:
      - Write in markdown format
      - Include clear sections with headers (##, ###)
      - Provide code examples where relevant using proper markdown code blocks
      - Make it educational, engaging, and practical
      - Target intermediate-level programmers
      - Length: 800-1200 words
      - Include an introduction and conclusion
      - Use real-world examples and best practices
      - Be technically accurate and up-to-date

      Write the article now:
    ADDITIONAL

    prompt
  end
end
