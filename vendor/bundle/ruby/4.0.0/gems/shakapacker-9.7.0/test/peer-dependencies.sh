#!/bin/bash

# Test script for verifying optional peer dependencies work correctly
# This ensures no warnings are shown during installation with different package managers

set -e

echo "Testing optional peer dependencies installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get the current directory (shakapacker root)
SHAKAPACKER_PATH=$(pwd)

# Create a temporary directory for tests
TEST_DIR=$(mktemp -d)
echo "Testing in: $TEST_DIR"

# Function to check for peer dependency warnings
check_warnings() {
    local output=$1
    local pkg_manager=$2

    # Check for common peer dependency warning patterns
    if echo "$output" | grep -i "peer" | grep -i "warn" > /dev/null 2>&1; then
        echo -e "${RED}✗ $pkg_manager shows peer dependency warnings${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $pkg_manager installation clean (no warnings)${NC}"
        return 0
    fi
}

# Test with npm
echo ""
echo "Testing with npm..."
mkdir -p "$TEST_DIR/npm-test"
cd "$TEST_DIR/npm-test"
npm init -y > /dev/null 2>&1
NPM_OUTPUT=$(npm install "$SHAKAPACKER_PATH" 2>&1)
check_warnings "$NPM_OUTPUT" "npm"
NPM_RESULT=$?

# Test with yarn
echo ""
echo "Testing with yarn..."
mkdir -p "$TEST_DIR/yarn-test"
cd "$TEST_DIR/yarn-test"
yarn init -y > /dev/null 2>&1
YARN_OUTPUT=$(yarn add "$SHAKAPACKER_PATH" 2>&1)
check_warnings "$YARN_OUTPUT" "yarn"
YARN_RESULT=$?

# Test with pnpm (if available)
if command -v pnpm &> /dev/null; then
    echo ""
    echo "Testing with pnpm..."
    mkdir -p "$TEST_DIR/pnpm-test"
    cd "$TEST_DIR/pnpm-test"
    pnpm init > /dev/null 2>&1
    PNPM_OUTPUT=$(pnpm add "$SHAKAPACKER_PATH" 2>&1)
    check_warnings "$PNPM_OUTPUT" "pnpm"
    PNPM_RESULT=$?
else
    echo ""
    echo "Skipping pnpm test (not installed)"
    PNPM_RESULT=0
fi

# Cleanup
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "===== Test Summary ====="
if [ $NPM_RESULT -eq 0 ] && [ $YARN_RESULT -eq 0 ] && [ $PNPM_RESULT -eq 0 ]; then
    echo -e "${GREEN}All tests passed! No peer dependency warnings detected.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Peer dependency warnings were detected.${NC}"
    exit 1
fi