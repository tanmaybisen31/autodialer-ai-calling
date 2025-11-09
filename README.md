# Autodialer - AI-Powered Automated Calling System

A Ruby on Rails application that automatically calls phone numbers using Twilio API with AI voice powered by Google Gemini.

## Features

- **Bulk Phone Number Management**: Upload/paste up to 100 phone numbers or generate test numbers
- **Autodialer**: Automatically calls numbers sequentially with configurable delays
- **AI Voice Integration**: Uses Google Gemini AI to generate natural conversation scripts
- **AI Command Interface**: Natural language commands like "call 9999999999"
- **Real-time Dashboard**: View call logs, statistics, and status updates
- **Call Status Tracking**: Monitor answered, failed, busy, and no-answer calls
- **Test Mode**: Generate 1800-XXX-XXXX test numbers for safe testing

## Prerequisites

- Ruby 3.0 or higher
- SQLite3
- Bundler
- Redis (for Sidekiq background jobs)

## Installation

### 1. Configure Environment Variables

Copy the example environment file and fill in your credentials:

```bash
cd autodialer
cp .env.example .env
```

Edit `.env` and fill in the required values:
- **TWILIO_ACCOUNT_SID**: Your Twilio Account SID
- **TWILIO_AUTH_TOKEN**: Your Twilio Auth Token
- **TWILIO_PHONE_NUMBER**: Your Twilio phone number (e.g., +1234567890)
- **GEMINI_API_KEY**: Your Google Gemini API key
- **OPENAI_API_KEY**: Your OpenAI API key (for blog generation)
- **NGROK_URL**: Your ngrok HTTPS URL (for development webhooks)

### 2. Install Dependencies

```bash
bundle install
```

### 3. Run Setup Script

```bash
./setup.sh
```

Or manually:

```bash
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed
```

### 3. Configure Twilio

Configure your Twilio credentials in the `.env` file:
- **Account SID**: Set `TWILIO_ACCOUNT_SID`
- **Auth Token**: Set `TWILIO_AUTH_TOKEN`
- **Phone Number**: Set `TWILIO_PHONE_NUMBER`

For production, use environment variables:

```bash
export TWILIO_ACCOUNT_SID="your_account_sid"
export TWILIO_AUTH_TOKEN="your_auth_token"
export TWILIO_PHONE_NUMBER="your_twilio_number"
```

### 4. Configure Gemini AI

Configure your Gemini API key in the `.env` file:
- **API Key**: Set `GEMINI_API_KEY`

For production:

```bash
export GEMINI_API_KEY="your_gemini_api_key"
```

### 5. Set Up Ngrok (Required for Twilio Webhooks)

Twilio needs to send webhooks to your local server. Use ngrok:

```bash
# Install ngrok if you haven't
brew install ngrok  # macOS
# or download from https://ngrok.com/

# Start ngrok
ngrok http 3000
```

Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`) and set it:

```bash
export NGROK_URL="https://abc123.ngrok.io"
```

## Running the Application

### 1. Start Redis (Required for Background Jobs)

```bash
redis-server
```

### 2. Start Sidekiq (In a separate terminal)

```bash
cd autodialer
bundle exec sidekiq
```

### 3. Start Rails Server (In another terminal)

```bash
cd autodialer
bundle exec rails server
```

### 4. Open Browser

Visit: http://localhost:3000

## Usage

### 1. Generate Test Numbers

Click **"Generate Test Numbers"** on the home page to create:
- 2 real numbers: **9999999999** and **8888888888** (will receive actual calls)
- 98 test numbers in 1800-XXX-XXXX format (toll-free, won't actually call)

### 2. Upload Custom Numbers

Paste phone numbers in the text area (one per line or comma-separated) and click **"Upload Numbers"**.

### 3. AI Command Interface

Use natural language to make calls:
- "call 9999999999"
- "make a call to 8888888888"
- "dial +919999999999"

The AI will parse your command and initiate the call.

### 4. Start Autodialer

1. Set delay between calls (default: 10 seconds)
2. Click **"Start Autodialer"**
3. The system will call all pending numbers sequentially
4. Monitor progress on the dashboard

### 5. View Call Logs

Visit the **Dashboard** to see:
- Total calls made
- Success/failure rates
- Call durations
- Real-time status updates
- Detailed call logs

## Project Structure

```
autodialer/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── calls_controller.rb       # Call management & AI commands
│   │   ├── dialer_controller.rb      # Main dashboard
│   │   ├── phone_numbers_controller.rb  # Number management
│   │   └── twilio_controller.rb      # Twilio webhooks
│   ├── models/
│   │   ├── call.rb                   # Call records
│   │   └── phone_number.rb           # Phone number storage
│   ├── services/
│   │   ├── autodialer_service.rb     # Autodialer logic
│   │   ├── gemini_service.rb         # AI integration
│   │   └── twilio_service.rb         # Twilio API wrapper
│   ├── jobs/
│   │   └── autodialer_job.rb         # Background calling job
│   └── views/
│       ├── layouts/
│       │   └── application.html.erb
│       └── dialer/
│           ├── index.html.erb        # Main control panel
│           └── dashboard.html.erb    # Call logs & stats
├── config/
│   ├── application.rb
│   ├── database.yml
│   ├── routes.rb
│   └── twilio.yml                    # Twilio configuration
├── db/
│   ├── migrate/
│   │   ├── 001_create_phone_numbers.rb
│   │   └── 002_create_calls.rb
│   └── seeds.rb
├── Gemfile
├── setup.sh
└── README.md
```

## API Endpoints

### Phone Numbers

- `GET /phone_numbers` - List all phone numbers
- `POST /phone_numbers` - Create a phone number
- `POST /phone_numbers/bulk_upload` - Upload multiple numbers
- `POST /phone_numbers/generate_test_numbers` - Generate test numbers
- `DELETE /phone_numbers/:id` - Delete a number

### Calls

- `GET /calls` - List all calls
- `GET /calls/:id` - Get call details
- `POST /calls/start_autodialer` - Start autodialer
- `POST /calls/stop_autodialer` - Stop autodialer
- `POST /calls/ai_command` - Execute AI command

### Twilio Webhooks

- `POST /twilio/voice` - Initial call TwiML
- `GET /twilio/gather` - Handle user input
- `POST /twilio/status` - Call status updates

## How It Works

### 1. Making a Call

```ruby
# The TwilioService makes calls
twilio_service = TwilioService.new
phone_number = PhoneNumber.find_by(number: '9999999999')
result = twilio_service.make_call(phone_number)
```

### 2. AI Voice Generation

When a call connects, Twilio requests TwiML from `/twilio/voice`:

```ruby
# GeminiService generates the script
gemini = GeminiService.new
script = gemini.generate_call_script(purpose: 'outreach')

# TwiML uses Indian English voice
response.say(message: script, voice: 'Polly.Aditi', language: 'en-IN')
```

### 3. AI Command Parsing

Commands like "call 9999999999" are parsed using Gemini:

```ruby
gemini = GeminiService.new
result = gemini.parse_command("call 9999999999")
# Returns: { action: "call", phone_number: "9999999999", country_code: "+91" }
```

### 4. Autodialer Flow

1. User clicks "Start Autodialer"
2. `AutodialerJob` is queued in Sidekiq
3. Service loops through pending numbers
4. Calls each number with configurable delay
5. Updates status in real-time
6. Twilio sends status webhooks to update database

## Configuration

### Twilio Voices

The app uses **Polly.Aditi** (Indian English female voice). Other options:
- `Polly.Raveena` - Indian English female
- `Polly.Aditi-Neural` - Neural version (higher quality)

Change in `app/services/twilio_service.rb` and `app/controllers/twilio_controller.rb`.

### Call Delays

Default: 10 seconds between calls. Adjustable in the UI or via API:

```ruby
AutodialerService.new.start(delay_between_calls: 15)
```

### AI Model

Using `gemini-2.0-flash:generateContent`. Change in `app/services/gemini_service.rb`.

## Testing

### Test Numbers

The seed data creates:
- **Real numbers**: 9999999999, 8888888888 (will receive actual calls)
- **Test numbers**: 1800XXXXXXX (for UI testing, won't actually dial)

### Making Test Calls

Use the AI command interface:

```
call 9999999999
```

Or start the autodialer with only real numbers in the database.

### Checking Logs

```bash
# Rails logs
tail -f log/development.log

# Sidekiq logs
# Check the terminal where Sidekiq is running
```

## Troubleshooting

### Calls Not Working

1. **Check Twilio credentials** in `config/twilio.yml`
2. **Verify phone number** is in E.164 format (+91XXXXXXXXXX)
3. **Check ngrok** is running and NGROK_URL is set
4. **Check Twilio console** for error messages

### Webhooks Not Received

1. **Ensure ngrok is running**: `ngrok http 3000`
2. **Set NGROK_URL** environment variable
3. **Check webhook URLs** in Twilio Console match your ngrok URL
4. **Check Rails logs** for incoming webhook requests

### AI Not Working

1. **Verify Gemini API key** is valid
2. **Check API quota** in Google Cloud Console
3. **See error logs** in Rails logs

### Background Jobs Not Running

1. **Ensure Redis is running**: `redis-cli ping` (should return PONG)
2. **Ensure Sidekiq is running**: Check the Sidekiq terminal
3. **Check Sidekiq web UI**: Add `require 'sidekiq/web'` and mount in routes

## Security Notes

- **Never commit** API keys or auth tokens to version control
- Use **environment variables** in production
- **Validate phone numbers** before calling
- **Rate limit** calls to avoid Twilio/API abuse
- **Secure your webhooks** with Twilio request validation (not implemented in this demo)

## Production Deployment

1. **Use environment variables** for all credentials
2. **Use PostgreSQL** instead of SQLite
3. **Deploy Redis** for Sidekiq
4. **Set up proper logging** and monitoring
5. **Configure CORS** if using API from frontend
6. **Enable Twilio request validation**
7. **Use SSL/HTTPS** for webhooks

## License

This is a demo application. Use responsibly and in compliance with Twilio's Terms of Service and local regulations regarding automated calling.

## Support

For issues or questions:
- Check Twilio Console for call logs
- Review Rails logs for application errors
- Check Gemini API quotas
- Ensure all services (Redis, Sidekiq, Rails) are running

## Credits

- **Twilio** - Voice API
- **Google Gemini** - AI integration
- **Ruby on Rails** - Web framework
- **Bootstrap** - UI framework
