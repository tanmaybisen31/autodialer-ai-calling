# Autodialer - Quick Start Guide

Get your Autodialer app running in 5 minutes!

## Prerequisites Checklist

- [ ] Ruby 3.0+ installed (`ruby -v`)
- [ ] Bundler installed (`gem install bundler`)
- [ ] Redis installed and running (`redis-server`)
- [ ] SQLite3 installed

## Quick Setup (3 Steps)

### Step 1: Install & Setup

```bash
cd autodialer
./setup.sh
```

This will:
- Install all Ruby gems
- Create the database
- Run migrations
- Seed with 100 phone numbers (2 real + 98 test numbers)

### Step 2: Start the App

```bash
./start.sh
```

This starts both Sidekiq and Rails server automatically.

### Step 3: Open Browser

Visit: **http://localhost:3000**

## Making Your First Call

### Option 1: AI Command (Easiest!)

1. Look for the purple **"AI Command Interface"** box
2. Type: `call 9999999999`
3. Press **Send**
4. Watch the call happen in real-time!

### Option 2: Use Autodialer

1. Click **"Generate Test Numbers"** (if not already done)
2. Set delay between calls (default: 10 seconds)
3. Click **"Start Autodialer"**
4. Watch calls being made automatically!

### Option 3: Bulk Upload

1. Paste phone numbers in the text area (one per line)
2. Click **"Upload Numbers"**
3. Click **"Start Autodialer"**

## Testing with Ngrok (For Real Calls)

If you want Twilio to send webhooks (for AI voice interaction):

```bash
# In a new terminal
ngrok http 3000
```

Copy the HTTPS URL and:

```bash
export NGROK_URL="https://abc123.ngrok.io"
```

Then restart the app.

## What Numbers Are Safe to Call?

### Real Numbers (WILL RECEIVE CALLS):
- **9999999999** ← Your test number 1
- **8888888888** ← Your test number 2

### Test Numbers (Safe - Won't Actually Call):
- All **1800-XXX-XXXX** numbers (toll-free format)
- Generated automatically by the app

## Viewing Results

### Dashboard
Click **"Dashboard"** in the nav bar to see:
- Total calls made
- Success/failure rates
- Call durations
- Detailed call logs

### Main Page
The home page shows:
- Recent calls (last 20)
- Current statistics
- Phone number list

## Common Commands

```bash
# Start everything
./start.sh

# Setup from scratch
./setup.sh

# Reset database
bundle exec rake db:reset
bundle exec rake db:seed

# Check logs
tail -f log/development.log

# Start services manually
redis-server                  # Terminal 1
bundle exec sidekiq          # Terminal 2
bundle exec rails server     # Terminal 3
```

## Troubleshooting

### "Redis is not running"
```bash
redis-server
```

### "Database not found"
```bash
./setup.sh
```

### Calls not working?
1. Check Twilio credentials in `config/twilio.yml`
2. Verify phone numbers are in correct format (+91XXXXXXXXXX)
3. Check Rails logs: `tail -f log/development.log`

### AI commands not working?
1. Check Gemini API key in `config/application.rb`
2. Check your API quota in Google Cloud Console

## Features to Try

1. **AI Commands**: `call 9999999999`, `make a call to 8888888888`
2. **Bulk Upload**: Paste 10 numbers and upload
3. **Autodialer**: Start with a 15-second delay
4. **Dashboard**: Watch real-time updates
5. **Call Logs**: See which numbers answered/failed

## Need Help?

- Read the full **README.md**
- Check **log/development.log** for errors
- Verify all services are running (Redis, Sidekiq, Rails)

## What's Pre-Configured?

✅ Twilio credentials (your account)
✅ Gemini API key
✅ Indian phone number format (+91)
✅ 2 real test numbers
✅ 98 test numbers (1800-XXX-XXXX)
✅ AI voice (Polly.Aditi - Indian English)

Just run `./setup.sh` and `./start.sh` - everything else is ready!

---

**Ready to go?** Run `./setup.sh` then `./start.sh`!
