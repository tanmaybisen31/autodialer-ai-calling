require 'twilio-ruby'

class TwilioService
  attr_reader :client, :config

  def initialize
    @config = Rails.application.config.twilio
    @client = Twilio::REST::Client.new(
      config['account_sid'],
      config['auth_token']
    )
  end

  def make_call(phone_number_record, options = {})
    Rails.logger.info "Making call to #{phone_number_record.formatted_number}"

    twiml_url = options[:twiml_url] || "#{base_url}/twilio/voice"
    status_callback_url = "#{base_url}/twilio/status"

    begin
      twilio_call = client.calls.create(
        from: config['phone_number'],
        to: phone_number_record.formatted_number,
        url: twiml_url,
        status_callback: status_callback_url,
        status_callback_event: ['initiated', 'ringing', 'answered', 'completed'],
        status_callback_method: 'POST',
        record: false # Set to true if you want to record calls
      )

      call = Call.create!(
        phone_number: phone_number_record,
        twilio_call_sid: twilio_call.sid,
        status: twilio_call.status,
        started_at: Time.current,
        call_type: options[:call_type] || 'autodialer',
        metadata: options[:metadata] || {}
      )

      phone_number_record.mark_called!

      Rails.logger.info "Call initiated: #{twilio_call.sid}"
      { success: true, call: call, twilio_call: twilio_call }

    rescue Twilio::REST::RestError => e
      Rails.logger.error "Twilio error: #{e.message}"

      call = Call.create!(
        phone_number: phone_number_record,
        status: 'failed',
        error_message: e.message,
        call_type: options[:call_type] || 'autodialer'
      )

      phone_number_record.update(status: 'failed')

      { success: false, error: e.message, call: call }
    end
  end

  def get_call_status(call_sid)
    begin
      twilio_call = client.calls(call_sid).fetch
      {
        success: true,
        status: twilio_call.status,
        duration: twilio_call.duration,
        direction: twilio_call.direction
      }
    rescue Twilio::REST::RestError => e
      { success: false, error: e.message }
    end
  end

  def cancel_call(call_sid)
    begin
      client.calls(call_sid).update(status: 'canceled')
      { success: true }
    rescue Twilio::REST::RestError => e
      { success: false, error: e.message }
    end
  end

  def generate_voice_twiml(message, options = {})
    Twilio::TwiML::VoiceResponse.new do |response|
      response.say(
        message: message,
        voice: options[:voice] || 'Polly.Aditi', # Indian English voice
        language: options[:language] || 'en-IN'
      )

      if options[:gather]
        response.gather(
          input: 'speech dtmf',
          action: options[:gather_action] || "#{base_url}/twilio/gather",
          method: 'GET',
          timeout: options[:timeout] || 5
        )
      end

      if options[:hangup]
        response.hangup
      end
    end.to_s
  end

  private

  def base_url
    if Rails.env.development?
      ENV['NGROK_URL'] || 'http://localhost:3000'
    else
      ENV['APP_URL'] || 'http://localhost:3000'
    end
  end
end
