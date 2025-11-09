require 'httparty'

class GeminiService
  include HTTParty
  base_uri 'https://generativelanguage.googleapis.com/v1beta'

  attr_reader :api_key

  def initialize
    @api_key = Rails.application.config.gemini_api_key
  end

  def generate_call_script(context = {})
    prompt = build_call_prompt(context)

    response = self.class.post(
      "/models/gemini-2.0-flash:generateContent",
      query: { key: api_key },
      headers: { 'Content-Type' => 'application/json' },
      body: {
        contents: [{
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 200
        }
      }.to_json
    )

    if response.success?
      text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
      { success: true, script: text&.strip || "Hello! This is an automated call." }
    else
      Rails.logger.error "Gemini API error: #{response.body}"
      { success: false, error: response.body, script: default_script }
    end
  rescue => e
    Rails.logger.error "Gemini service error: #{e.message}"
    { success: false, error: e.message, script: default_script }
  end

  def parse_command(command_text)
    local_result = local_parse_command(command_text)
    return local_result if local_result[:success]

    prompt = <<~PROMPT
      Parse this voice/text command and extract the action and phone number.
      Command: "#{command_text}"

      Respond ONLY with JSON in this exact format:
      {"action": "call", "phone_number": "1234567890", "country_code": "+91"}

      If no valid phone number is found, use:
      {"action": "unknown", "phone_number": null, "error": "reason"}
    PROMPT

    response = self.class.post(
      "/models/gemini-2.0-flash:generateContent",
      query: { key: api_key },
      headers: { 'Content-Type' => 'application/json' },
      body: {
        contents: [{
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 100
        }
      }.to_json
    )

    if response.success?
      text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
      json_text = text.match(/\{.*\}/m)&.[](0) || text
      parsed = JSON.parse(json_text)
      { success: true, parsed: parsed }
    else
      { success: false, error: response.body }
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Gemini JSON response: #{e.message}"
    { success: false, error: "Could not parse command", raw_response: text }
  rescue => e
    Rails.logger.error "Command parsing error: #{e.message}"
    { success: false, error: e.message }
  end

  def local_parse_command(command_text)
    return { success: false } if command_text.blank?

    text = command_text.downcase.strip

    phone_patterns = [
      /(?:call|dial|phone|ring)\s*(?:to|number)?\s*(\+?\d{10,13})/i,  # "call 8888888888"
      /(\+?\d{10,13})/,  # Just the number
      /(\d{3}[-.\s]?\d{3}[-.\s]?\d{4})/  # Formatted numbers
    ]

    phone_patterns.each do |pattern|
      match = text.match(pattern)
      if match
        phone_number = match[1].gsub(/[-.\s]/, '')  # Remove formatting

        country_code = if phone_number.start_with?('+91')
          '+91'
        elsif phone_number.start_with?('91') && phone_number.length > 10
          '+91'
        else
          '+91'  # Default to India
        end

        clean_number = phone_number.gsub(/^\+?91/, '').gsub(/^0/, '')

        return {
          success: true,
          parsed: {
            'action' => 'call',
            'phone_number' => clean_number,
            'country_code' => country_code
          }
        }
      end
    end

    { success: false }
  end

  def generate_conversation_response(user_input, context = {})
    prompt = <<~PROMPT
      You are Aastha, having a friendly conversation on the phone. The person said: "#{user_input}"

      Respond naturally and conversationally in Hindi. Be friendly, engaging, and open to discussing any topic they bring up.
      Keep responses conversational and not too formal. Respond in Hindi language only.
      Do not mention being an AI or any technical details.
    PROMPT

    response = self.class.post(
      "/models/gemini-2.0-flash:generateContent",
      query: { key: api_key },
      headers: { 'Content-Type' => 'application/json' },
      body: {
        contents: [{
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.8,
          maxOutputTokens: 150
        }
      }.to_json
    )

    if response.success?
      text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
      { success: true, response: text&.strip || "Thank you for your time." }
    else
      { success: false, error: response.body, response: "Thank you for your time." }
    end
  end

  private

  def build_call_prompt(context)
    purpose = context[:purpose] || 'general outreach'
    name = context[:name] || 'there'

    <<~PROMPT
      Generate exactly this greeting in Hindi: "मैं आस्था बोल रही हूं आप मुझसे क्या बात करना चाहते हैं"
      Do not add any extra text, instructions, or meta-commentary. Just the greeting.
    PROMPT
  end

  def default_script
    "नमस्ते! यह ऑटोडायलर से एक स्वचालित कॉल है। आपके समय के लिए धन्यवाद। अलविदा!"
  end

  def self.generate_article(title:, description: nil, tags: nil)
    service = new
    service.generate_blog_article(title: title, description: description, tags: tags)
  end

  def generate_blog_article(title:, description: nil, tags: nil)
    prompt = build_article_prompt(title: title, description: description, tags: tags)

    response = self.class.post(
      "/models/gemini-2.0-flash:generateContent",
      query: { key: api_key },
      headers: { 'Content-Type' => 'application/json' },
      body: {
        contents: [{
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 2048
        }
      }.to_json
    )

    if response.success?
      text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
      text&.strip || "Article content could not be generated."
    else
      Rails.logger.error "Gemini API error: #{response.body}"
      raise "Failed to generate article: #{response.body}"
    end
  rescue => e
    Rails.logger.error "Article generation error: #{e.message}"
    raise "Error generating article: #{e.message}"
  end

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
