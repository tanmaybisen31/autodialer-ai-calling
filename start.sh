
echo "========================================="
echo "Starting Autodialer Application"
echo "========================================="
echo ""

if ! redis-cli ping &> /dev/null; then
    echo "❌ Redis is not running!"
    echo "Please start Redis first:"
    echo "  redis-server"
    echo ""
    exit 1
fi

echo "✓ Redis is running"

if [ ! -f "db/development.sqlite3" ]; then
    echo "❌ Database not found!"
    echo "Please run setup first:"
    echo "  ./setup.sh"
    echo ""
    exit 1
fi

echo "✓ Database found"

echo "Starting Sidekiq..."
bundle exec sidekiq &
SIDEKIQ_PID=$!
echo "✓ Sidekiq started (PID: $SIDEKIQ_PID)"

sleep 2

echo "Starting Rails server..."
echo ""
echo "========================================="
echo "Application Starting!"
echo "========================================="
echo ""
echo "Visit: http://localhost:3000"
echo ""
echo "To stop the application:"
echo "  Press Ctrl+C"
echo ""
echo "========================================="
echo ""

trap "echo 'Stopping Sidekiq...'; kill $SIDEKIQ_PID 2>/dev/null; exit" INT TERM

bundle exec rails server

kill $SIDEKIQ_PID 2>/dev/null
