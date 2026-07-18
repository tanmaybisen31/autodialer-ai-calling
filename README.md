# AI-Powered Autodialer

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Ruby on Rails](https://img.shields.io/badge/Rails-7.0-CC0000.svg?logo=rubyonrails&logoColor=white)

A Ruby on Rails application that places automated outbound phone calls through Twilio and holds a short, AI-generated voice conversation with the person who answers, using Google Gemini for the script and Twilio's text-to-speech for playback.

## Overview

The core of the project is an **autodialer**: it works through a list of stored phone numbers and calls them one at a time with a configurable delay between calls.

The calling flow is:

1. **Dial:** `AutodialerService` selects all `pending` phone numbers and, for each one, `TwilioService` places an outbound call via the Twilio REST API. The dialing loop runs in the background through a Sidekiq job (`AutodialerJob`).
2. **Speak:** when the callee answers, Twilio requests the `/twilio/voice` webhook. That endpoint asks Google Gemini (`gemini-2.0-flash`) to generate a short greeting/script, and returns TwiML that speaks it using Twilio's built-in TTS (the `Polly.Aditi` voice, configured for Hindi).
3. **Listen & respond:** the TwiML uses Twilio `<Gather>` to capture the callee's speech or keypad input. That input is posted to `/twilio/gather`, which sends it back to Gemini for a conversational reply, speaks the reply, and then ends the call.
4. **Track:** Twilio posts call lifecycle events to `/twilio/status`, which updates the matching `Call` record (answered, busy, failed, no-answer, duration, etc.).

There is also an **AI command endpoint** (`POST /calls/ai_command`): it takes free-text like `"call 8888888888"`, extracts the number (regex-based parsing first, with a Gemini fallback), and triggers a single call.

A web dashboard (`/` and `/dashboard`) shows phone numbers, recent calls, and aggregate statistics.

### Secondary module: blog generation + RAG

The repository also bundles a separate content module that is independent of the calling feature: it generates programming blog articles (via Gemini or OpenAI `gpt-4o-mini`), stores them, creates embeddings with Gemini's `text-embedding-004`, and answers questions over them using a simple retrieval-augmented-generation flow (`RagService`) plus semantic search. This is a self-contained demo and not required for the autodialer to work.

## Tech stack

- **Language / framework:** Ruby (~> 3.0), Ruby on Rails 7.0
- **Telephony:** Twilio (`twilio-ruby`) for outbound calls, TwiML, and TTS
- **AI:** Google Gemini (`gemini-2.0-flash` for scripts/replies, `text-embedding-004` for embeddings) via HTTParty; OpenAI `gpt-4o-mini` for blog generation
- **Background jobs:** Sidekiq + Redis
- **Database:** SQLite3 (via Active Record)
- **Server / assets:** Puma, Importmap, Turbo, Stimulus, Sprockets
- **Local webhooks:** ngrok (to expose the dev server to Twilio)

## Prerequisites

- Ruby 3.0+ and Bundler
- SQLite3
- Redis (for Sidekiq)
- A Twilio account with a voice-capable phone number
- A Google Gemini API key (an OpenAI key is optional, only for blog generation)
- ngrok, or another public tunnel, so Twilio can reach your webhooks in development

Run `./check-prerequisites.sh` to verify the local tooling.

## Setup

1. **Configure environment variables**

   ```bash
   cp .env.example .env
   ```

   Then fill in `.env`:

   - `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER`
   - `GEMINI_API_KEY`
   - `OPENAI_API_KEY` (optional, blog generation only)
   - `NGROK_URL` (your public HTTPS tunnel URL for dev webhooks)

2. **Install dependencies and prepare the database**

   ```bash
   ./setup.sh        # bundle install + db:create, db:migrate, db:seed
   ```

   or run the steps manually with `bundle install` and `bundle exec rake db:create db:migrate db:seed`.

   > Note: the seed data creates sample/test phone numbers. Review `db/seeds.rb` before running it against real credentials.

## Usage

1. Start Redis (`redis-server`).
2. Start the app and worker together with `./start.sh`, or run them separately:

   ```bash
   bundle exec sidekiq          # background dialing jobs
   bundle exec rails server     # web UI + webhooks
   ```

3. (For live calls) start a tunnel so Twilio can reach the app, and set `NGROK_URL`:

   ```bash
   ngrok http 3000
   ```

4. Open `http://localhost:3000`, add phone numbers, and start the autodialer from the dashboard. Calls, statuses, and statistics update as Twilio posts back to the webhooks.

## Scope and limitations

This is a personal/experimental project. A few honest caveats:

- **Language and persona are hardcoded.** The generated greetings and replies are written for a specific Hindi-speaking persona, and the TTS voice/language (`Polly.Aditi`, `hi-IN`/`en-IN`) are set directly in the controllers rather than configurable.
- **No authentication.** The dashboard and API endpoints are unauthenticated and intended for local/single-user use.
- **Webhook security is minimal.** CSRF protection is skipped on the Twilio webhooks (as expected for callbacks), but Twilio request-signature validation is not implemented.
- **The dialer is a simple sequential loop.** It calls numbers one at a time using an in-process delay inside a single background job; it is not built for high-volume or concurrent campaigns.
- **SQLite + development-oriented config.** Fine for testing; not tuned for production deployment.
- **The RAG module is a demo.** It recomputes embeddings during retrieval and is not optimized for large article sets.

Live calling requires valid Twilio credentials, a real destination number, and a publicly reachable webhook URL. Always comply with local calling/consent regulations before dialing real numbers.

## License

Released under the [MIT License](LICENSE).
