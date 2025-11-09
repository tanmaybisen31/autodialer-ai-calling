require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module Autodialer
  class Application < Rails::Application
    config.load_defaults 7.0

    logger = ActiveSupport::Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    config.logger = logger
    config.log_level = :debug

    config.middleware.delete Rails::Rack::Logger

    config.active_job.queue_adapter = :sidekiq

    config.twilio = config_for(:twilio)

    config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', 'your_gemini_api_key_here')
  end
end
