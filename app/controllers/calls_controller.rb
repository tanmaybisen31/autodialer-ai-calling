class CallsController < ApplicationController
  def index
    @calls = Call.includes(:phone_number).recent.limit(100)
    render json: @calls.as_json(include: :phone_number)
  end

  def show
    @call = Call.find(params[:id])
    render json: @call.as_json(include: :phone_number)
  end

  def status
    @call = Call.find(params[:id])

    twilio_service = TwilioService.new
    result = twilio_service.get_call_status(@call.twilio_call_sid)

    if result[:success]
      @call.update(
        status: result[:status],
        duration: result[:duration]
      )
    end

    render json: {
      success: true,
      call: @call,
      twilio_status: result
    }
  end

  def start_autodialer
    delay = (params[:delay] || 10).to_i

    autodialer = AutodialerService.new

    result = autodialer.start_async(delay_between_calls: delay)

    render json: result
  end

  def stop_autodialer
    autodialer = AutodialerService.new
    result = autodialer.stop

    render json: result
  end

  def ai_command
    command_text = params[:command]

    return render json: { success: false, error: "No command provided" }, status: :bad_request if command_text.blank?

    gemini_service = GeminiService.new
    parse_result = gemini_service.parse_command(command_text)

    if parse_result[:success]
      parsed = parse_result[:parsed]

      case parsed['action']
      when 'call'
        phone_number_str = parsed['phone_number']

        return render json: {
          success: false,
          error: "No phone number found in command",
          parsed: parsed
        } unless phone_number_str

        phone_number = PhoneNumber.find_or_create_by(number: phone_number_str) do |pn|
          pn.country_code = parsed['country_code'] || '+91'
          pn.name = "AI Command Contact"
        end

        twilio_service = TwilioService.new
        call_result = twilio_service.make_call(
          phone_number,
          call_type: 'ai_command',
          metadata: { command: command_text }
        )

        render json: {
          success: true,
          message: "Calling #{phone_number.formatted_number}...",
          call: call_result[:call],
          parsed_command: parsed
        }

      when 'unknown'
        render json: {
          success: false,
          error: parsed['error'] || "Could not understand command",
          parsed: parsed
        }

      else
        render json: {
          success: false,
          error: "Action '#{parsed['action']}' not supported",
          parsed: parsed
        }
      end
    else
      render json: {
        success: false,
        error: "Failed to parse command: #{parse_result[:error]}",
        raw_response: parse_result[:raw_response]
      }
    end
  end
end
