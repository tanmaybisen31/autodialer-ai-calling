class AutodialerService
  attr_reader :twilio_service

  def initialize
    @twilio_service = TwilioService.new
    @is_running = false
  end

  def start(delay_between_calls: 10)
    return { success: false, error: "Autodialer already running" } if running?

    @is_running = true

    pending_numbers = PhoneNumber.pending.order(:created_at)

    Rails.logger.info "Starting autodialer with #{pending_numbers.count} numbers"

    results = {
      total: pending_numbers.count,
      successful: 0,
      failed: 0,
      calls: []
    }

    pending_numbers.each_with_index do |phone_number, index|
      break unless @is_running

      Rails.logger.info "Calling #{index + 1}/#{pending_numbers.count}: #{phone_number.formatted_number}"

      result = twilio_service.make_call(phone_number)

      if result[:success]
        results[:successful] += 1
      else
        results[:failed] += 1
      end

      results[:calls] << {
        phone_number: phone_number.formatted_number,
        success: result[:success],
        call_id: result[:call]&.id,
        error: result[:error]
      }

      sleep(delay_between_calls) if index < pending_numbers.count - 1 && @is_running
    end

    @is_running = false

    Rails.logger.info "Autodialer finished: #{results[:successful]} successful, #{results[:failed]} failed"

    results.merge(success: true)
  end

  def start_async(delay_between_calls: 10)
    AutodialerJob.perform_later(delay_between_calls)
    { success: true, message: "Autodialer started in background" }
  end

  def stop
    @is_running = false
    { success: true, message: "Autodialer stopping..." }
  end

  def running?
    @is_running
  end

  def self.statistics
    {
      total_phone_numbers: PhoneNumber.count,
      pending: PhoneNumber.pending.count,
      completed: PhoneNumber.where(status: 'completed').count,
      failed: PhoneNumber.where(status: 'failed').count,
      total_calls: Call.count,
      successful_calls: Call.successful.count,
      failed_calls: Call.failed.count,
      active_calls: Call.active.count,
      average_call_duration: Call.successful.average(:duration)&.to_f&.round(2) || 0
    }
  end
end
