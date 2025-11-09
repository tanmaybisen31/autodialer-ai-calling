source 'https://rubygems.org'

ruby '~> 3.0'

# Core Rails
gem 'rails', '~> 7.0'
gem 'sqlite3', '~> 1.4'
gem 'puma', '~> 6.0'

# Twilio integration
gem 'twilio-ruby', '~> 6.0'

# HTTP client for Gemini API
gem 'httparty', '~> 0.21'

# Background jobs
gem 'sidekiq', '~> 7.0'

# Assets
gem 'sprockets-rails'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'

# Build JSON APIs
gem 'jbuilder'

# Reduce boot times through caching
gem 'bootsnap', require: false

group :development, :test do
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]
  gem 'dotenv-rails'
end

group :development do
  gem 'web-console'
end
