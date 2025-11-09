
echo "========================================="
echo "Checking Prerequisites for Autodialer"
echo "========================================="
echo ""

ALL_GOOD=true

echo -n "Checking Ruby... "
if command -v ruby &> /dev/null; then
    VERSION=$(ruby -v)
    echo "✓ $VERSION"
else
    echo "❌ Ruby not found!"
    echo "   Install: https://www.ruby-lang.org/en/downloads/"
    ALL_GOOD=false
fi

echo -n "Checking Bundler... "
if command -v bundle &> /dev/null; then
    VERSION=$(bundle -v)
    echo "✓ $VERSION"
else
    echo "❌ Bundler not found!"
    echo "   Install: gem install bundler"
    ALL_GOOD=false
fi

echo -n "Checking SQLite3... "
if command -v sqlite3 &> /dev/null; then
    VERSION=$(sqlite3 --version | awk '{print $1}')
    echo "✓ SQLite3 $VERSION"
else
    echo "❌ SQLite3 not found!"
    echo "   Install: brew install sqlite3 (macOS)"
    ALL_GOOD=false
fi

echo -n "Checking Redis... "
if command -v redis-server &> /dev/null; then
    VERSION=$(redis-server --version | awk '{print $3}')
    echo "✓ Redis $VERSION"

    echo -n "Checking if Redis is running... "
    if redis-cli ping &> /dev/null; then
        echo "✓ Running"
    else
        echo "⚠️  Not running"
        echo "   Start with: redis-server"
    fi
else
    echo "❌ Redis not found!"
    echo "   Install: brew install redis (macOS)"
    ALL_GOOD=false
fi

echo -n "Checking ngrok (optional)... "
if command -v ngrok &> /dev/null; then
    VERSION=$(ngrok version | head -n1)
    echo "✓ $VERSION"
else
    echo "⚠️  Not found (optional for webhooks)"
    echo "   Install: brew install ngrok (macOS)"
    echo "   Or: https://ngrok.com/download"
fi

echo ""
echo "========================================="

if [ "$ALL_GOOD" = true ]; then
    echo "✓ All prerequisites installed!"
    echo ""
    echo "You're ready to go! Run:"
    echo "  ./setup.sh"
    echo "  ./start.sh"
else
    echo "❌ Some prerequisites are missing."
    echo ""
    echo "Please install missing items and run this script again."
fi

echo "========================================="
