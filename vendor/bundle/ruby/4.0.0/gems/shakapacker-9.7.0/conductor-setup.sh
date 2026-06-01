#!/bin/zsh
set -euo pipefail

echo "🔧 Setting up Shakapacker workspace..."

# Detect and initialize version manager
# Supports: mise, asdf, or direct PATH (rbenv/nvm/nodenv already in PATH)
VERSION_MANAGER="none"

echo "📋 Detecting version manager..."

if command -v mise &> /dev/null; then
    VERSION_MANAGER="mise"
    echo "✅ Found mise"
    # Trust mise config for current directory only
    mise trust 2>/dev/null || true
elif [[ -f ~/.asdf/asdf.sh ]]; then
    VERSION_MANAGER="asdf"
    source ~/.asdf/asdf.sh
    echo "✅ Found asdf (from ~/.asdf/asdf.sh)"
elif command -v asdf &> /dev/null; then
    VERSION_MANAGER="asdf"
    # For homebrew-installed asdf
    if [[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ]]; then
        source /opt/homebrew/opt/asdf/libexec/asdf.sh
    fi
    echo "✅ Found asdf"
else
    echo "ℹ️  No version manager detected, using system PATH"
    echo "   (Assuming rbenv/nvm/nodenv or system tools are already configured)"
fi

# Ensure version config exists for asdf/mise users
if [[ "$VERSION_MANAGER" != "none" ]] && [[ ! -f .tool-versions ]] && [[ ! -f .mise.toml ]]; then
    echo "📝 Creating .tool-versions from project version files..."

    # Read Ruby version from .ruby-version or use default
    if [[ -f .ruby-version ]]; then
        RUBY_VER=$(cat .ruby-version | tr -d '[:space:]')
    else
        RUBY_VER="3.3.4"  # Default: recent stable Ruby
    fi

    # Read Node version from .node-version or use default
    if [[ -f .node-version ]]; then
        NODE_VER=$(cat .node-version | tr -d '[:space:]')
    else
        NODE_VER="20.18.0"  # Default: LTS Node
    fi

    cat > .tool-versions << EOF
ruby $RUBY_VER
nodejs $NODE_VER
EOF
    echo "   Using Ruby $RUBY_VER, Node $NODE_VER"
fi

# Install tools via mise (after .tool-versions exists)
if [[ "$VERSION_MANAGER" == "mise" ]]; then
    echo "📦 Installing tools via mise..."
    mise install
fi

# Helper function to run commands with the detected version manager
run_cmd() {
    if [[ "$VERSION_MANAGER" == "mise" ]] && [[ -x "bin/conductor-exec" ]]; then
        bin/conductor-exec "$@"
    else
        "$@"
    fi
}

# Check required tools
echo "📋 Checking required tools..."
run_cmd ruby --version >/dev/null 2>&1 || { echo "❌ Error: Ruby is not installed or not in PATH."; exit 1; }
run_cmd node --version >/dev/null 2>&1 || { echo "❌ Error: Node.js is not installed or not in PATH."; exit 1; }

# Check Ruby version
RUBY_VERSION=$(run_cmd ruby -v | awk '{print $2}')
MIN_RUBY_VERSION="2.7.0"
if [[ $(echo -e "$MIN_RUBY_VERSION\n$RUBY_VERSION" | sort -V | head -n1) != "$MIN_RUBY_VERSION" ]]; then
    echo "❌ Error: Ruby version $RUBY_VERSION is too old. Shakapacker requires Ruby >= 2.7.0"
    echo "   Please upgrade Ruby using your version manager or system package manager."
    exit 1
fi
echo "✅ Ruby version: $RUBY_VERSION"

# Check Node version
NODE_VERSION=$(run_cmd node -v | cut -d'v' -f2)
MIN_NODE_VERSION="14.0.0"
if [[ $(echo -e "$MIN_NODE_VERSION\n$NODE_VERSION" | sort -V | head -n1) != "$MIN_NODE_VERSION" ]]; then
    echo "❌ Error: Node.js version v$NODE_VERSION is too old. Shakapacker requires Node.js >= 14.0.0"
    echo "   Please upgrade Node.js using your version manager or system package manager."
    exit 1
fi
echo "✅ Node.js version: v$NODE_VERSION"

# Copy any environment files from root if they exist
if [ -n "${CONDUCTOR_ROOT_PATH:-}" ]; then
    if [ -f "$CONDUCTOR_ROOT_PATH/.env" ]; then
        echo "📝 Copying .env file..."
        cp "$CONDUCTOR_ROOT_PATH/.env" .env
    fi

    if [ -f "$CONDUCTOR_ROOT_PATH/.env.local" ]; then
        echo "📝 Copying .env.local file..."
        cp "$CONDUCTOR_ROOT_PATH/.env.local" .env.local
    fi
fi

# Install Ruby dependencies
echo "💎 Installing Ruby dependencies..."
run_cmd bundle install

# Install JavaScript dependencies
echo "📦 Installing JavaScript dependencies..."
run_cmd yarn install --frozen-lockfile

# Set up Husky git hooks
echo "🪝 Setting up Husky git hooks..."
run_cmd npx husky
if [ ! -f .husky/pre-commit ]; then
    echo "Creating pre-commit hook..."
    cat > .husky/pre-commit << 'EOF'
#!/usr/bin/env sh
npx lint-staged
EOF
    chmod +x .husky/pre-commit
fi

# Verify linting tools are available
echo "✅ Verifying linting tools..."
run_cmd bundle exec rubocop --version

echo "✨ Workspace setup complete!"
echo ""
echo "📚 Key commands:"
echo "  • bundle exec rspec - Run Ruby tests"
echo "  • bundle exec rake run_spec:gem - Run gem-specific tests"
echo "  • yarn test - Run JavaScript tests"
echo "  • yarn lint - Run JavaScript linting"
echo "  • bundle exec rubocop - Run Ruby linting (required before commits)"
echo ""
if [[ "$VERSION_MANAGER" == "mise" ]]; then
    echo "💡 Tip: Use 'bin/conductor-exec <command>' if tool versions aren't detected correctly."
fi
echo "⚠️ Remember: Always run 'bundle exec rubocop' before committing!"
