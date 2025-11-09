require 'httparty'
require 'json'

class EmbeddingService
  include HTTParty
  base_uri 'https://generativelanguage.googleapis.com/v1beta'

  attr_reader :api_key

  def initialize
    @api_key = Rails.application.config.gemini_api_key
  end

  def self.generate_embedding(text)
    service = new
    service.generate_embedding(text)
  end

  def generate_embedding(text)
    return nil if text.blank?

    response = self.class.post(
      "/models/text-embedding-004:embedContent",
      query: { key: api_key },
      headers: { 'Content-Type' => 'application/json' },
      body: {
        model: "models/text-embedding-004",
        content: {
          parts: [{ text: text }]
        }
      }.to_json
    )

    if response.success?
      embedding_values = response.dig('embedding', 'values')

      if embedding_values.is_a?(Array)
        embedding_values.to_json
      else
        Rails.logger.error "Invalid embedding response format: #{response.body}"
        nil
      end
    else
      Rails.logger.error "Gemini Embedding API error: #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "Embedding generation error: #{e.message}"
    nil
  end

  def self.cosine_similarity(vector_a, vector_b)
    return 0.0 if vector_a.nil? || vector_b.nil?
    return 0.0 if vector_a.empty? || vector_b.empty?
    return 0.0 if vector_a.length != vector_b.length

    dot_product = vector_a.zip(vector_b).map { |a, b| a * b }.sum

    magnitude_a = Math.sqrt(vector_a.map { |x| x**2 }.sum)
    magnitude_b = Math.sqrt(vector_b.map { |x| x**2 }.sum)

    return 0.0 if magnitude_a.zero? || magnitude_b.zero?

    similarity = dot_product / (magnitude_a * magnitude_b)

    [[similarity, 1.0].min, -1.0].max
  end

  def self.text_similarity(text, stored_embedding_json)
    return 0.0 if text.blank? || stored_embedding_json.blank?

    query_embedding_json = generate_embedding(text)
    return 0.0 if query_embedding_json.nil?

    query_vector = JSON.parse(query_embedding_json)
    stored_vector = JSON.parse(stored_embedding_json)

    cosine_similarity(query_vector, stored_vector)
  rescue JSON::ParserError => e
    Rails.logger.error "Error parsing embeddings: #{e.message}"
    0.0
  end
end
