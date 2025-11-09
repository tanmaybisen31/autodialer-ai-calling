
echo "========================================="
echo "Autodialer Setup Script"
echo "========================================="
echo ""

if ! command -v bundle &> /dev/null; then
    echo "Installing bundler..."
    gem install bundler
fi

echo "Installing dependencies..."
bundle install

echo "Creating database..."
bundle exec rake db:create

echo "Running migrations..."
bundle exec rake db:migrate

echo "Seeding database with test data..."
bundle exec rake db:seed

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "To start the application:"
echo "  1. Start Sidekiq (for background jobs):"
echo "     bundle exec sidekiq"
echo ""
echo "  2. Start Rails server (in another terminal):"
echo "     bundle exec rails server"
echo ""
echo "  3. (Optional) Start ngrok for Twilio webhooks:"
echo "     ngrok http 3000"
echo "     Then set NGROK_URL environment variable"
echo ""
echo "  4. Visit: http://localhost:3000"
echo ""
echo "========================================="
