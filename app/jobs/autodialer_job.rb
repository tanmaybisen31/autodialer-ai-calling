class AutodialerJob < ApplicationJob
  queue_as :default

  def perform(delay_between_calls = 10)
    Rails.logger.info "AutodialerJob started with delay: #{delay_between_calls}s"

    autodialer = AutodialerService.new
    result = autodialer.start(delay_between_calls: delay_between_calls)

    Rails.logger.info "AutodialerJob completed: #{result.inspect}"
  end
end
