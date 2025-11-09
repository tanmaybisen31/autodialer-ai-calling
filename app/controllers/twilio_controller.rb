class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def voice
    Rails.logger.info "Twilio voice webhook called: #{params.inspect}"

    call = Call.find_by(twilio_call_sid: params['CallSid'])

    gemini_service = GeminiService.new
    script_result = gemini_service.generate_call_script(
      purpose: 'automated outreach',
      name: call&.phone_number&.name || 'there'
    )

    message = script_result[:script]

    response = Twilio::TwiML::VoiceResponse.new do |r|
      r.say(
        message: message,
        voice: 'Polly.Aditi', # Indian voice supporting Hindi
        language: 'hi-IN'
      )

      r.gather(
        input: 'speech dtmf',
        action: twilio_gather_path,
        method: 'GET',
        timeout: 5,
        speech_timeout: 'auto'
      ) do |gather|
        gather.say(
          message: "कृपया 1 दबाएं या कुछ कहें।",
          voice: 'Polly.Aditi',
          language: 'hi-IN'
        )
      end

      r.pause(length: 2)
      r.say(message: "आपका समय देने के लिए धन्यवाद। अलविदा!", voice: 'Polly.Aditi', language: 'hi-IN')
      r.hangup
    end

    call&.update(ai_transcript: message)

    render xml: response.to_s
  end

  def gather
    Rails.logger.info "Twilio gather webhook: #{params.inspect}"

    user_input = params['SpeechResult'] || params['Digits']
    call = Call.find_by(twilio_call_sid: params['CallSid'])

    if user_input.present?
      gemini_service = GeminiService.new
      ai_response = gemini_service.generate_conversation_response(
        user_input,
        purpose: 'responding to user during automated call'
      )

      message = ai_response[:response]

      if call
        current_transcript = call.ai_transcript || ""
        call.update(ai_transcript: "#{current_transcript}\nUser: #{user_input}\nAI: #{message}")
      end

      response = Twilio::TwiML::VoiceResponse.new do |r|
        r.say(message: message, voice: 'Polly.Aditi', language: 'hi-IN')
        r.pause(length: 1)
        r.say(message: "अलविदा!", voice: 'Polly.Aditi', language: 'hi-IN')
        r.hangup
      end
    else
      response = Twilio::TwiML::VoiceResponse.new do |r|
        r.say(message: "मैंने वह नहीं सुना। अलविदा!", voice: 'Polly.Aditi', language: 'hi-IN')
        r.hangup
      end
    end

    render xml: response.to_s
  end

  def status
    Rails.logger.info "Twilio status webhook: #{params.inspect}"

    call_sid = params['CallSid']
    call = Call.find_by(twilio_call_sid: call_sid)

    if call
      call.update_from_twilio_callback(params)
      Rails.logger.info "Updated call #{call.id} status to #{params['CallStatus']}"
    else
      Rails.logger.warn "Call not found for SID: #{call_sid}"
    end

    head :ok
  end
end
