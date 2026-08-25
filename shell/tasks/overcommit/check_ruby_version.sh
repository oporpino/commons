#!/bin/bash

# CheckRubyVersion
# This script ensures all Ruby version declarations are consistent across the project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"

echo "Checking Ruby version consistency..."

# Extract Ruby version from .ruby-version
if [ ! -f "$PROJECT_ROOT/.ruby-version" ]; then
    echo "ERROR: .ruby-version file not found!"
    exit 1
fi

RUBY_VERSION=$(cat "$PROJECT_ROOT/.ruby-version" | tr -d '[:space:]')

if [ -z "$RUBY_VERSION" ]; then
    echo "ERROR: .ruby-version file is empty!"
    exit 1
fi

echo "Reference Ruby version from .ruby-version: $RUBY_VERSION"

# Function to check version consistency
check_version_consistency() {
    local file_path="$1"
    local expected_pattern="$2"
    local description="$3"
    local required="$4"
    
    if [ ! -f "$file_path" ]; then
        if [ "$required" = "true" ]; then
            echo "ERROR: $description file not found: $file_path"
            return 1
        else
            echo "WARNING: $description file not found: $file_path"
            return 0
        fi
    fi
    
    if ! grep -q "$expected_pattern" "$file_path"; then
        echo "ERROR: Ruby version mismatch in $description"
        echo "  File: $file_path"
        echo "  Expected pattern: $expected_pattern"
        echo "  Current content:"
        cat "$file_path" | head -10
        return 1
    fi
    
    echo "✓ $description version is consistent"
    return 0
}

# Check consistency across files
ERRORS=0

# Check .tool-versions (required)
if ! check_version_consistency "$PROJECT_ROOT/.tool-versions" "ruby $RUBY_VERSION" ".tool-versions" "true"; then
    ERRORS=$((ERRORS + 1))
fi

# Check Dockerfile (optional)
if ! check_version_consistency "$PROJECT_ROOT/Dockerfile" "ARG RUBY_VERSION=$RUBY_VERSION" "Dockerfile" "false"; then
    ERRORS=$((ERRORS + 1))
fi

# Check Gemfile references .ruby-version correctly (required)
if ! check_version_consistency "$PROJECT_ROOT/Gemfile" 'ruby file: ".ruby-version"' "Gemfile" "true"; then
    ERRORS=$((ERRORS + 1))
fi

# Check .standard.yml (optional)
if ! check_version_consistency "$PROJECT_ROOT/.standard.yml" "ruby_version: $RUBY_VERSION" ".standard.yml" "false"; then
    ERRORS=$((ERRORS + 1))
fi

# Check for any hardcoded Ruby versions that don't match
echo "Checking for hardcoded Ruby versions..."

# Search for potential hardcoded versions (excluding known good files)
HARDCODED_VERSIONS=$(grep -r "ruby.*[0-9]\+\.[0-9]\+\.[0-9]\+" "$PROJECT_ROOT" \
    --exclude-dir=.git \
    --exclude-dir=node_modules \
    --exclude-dir=vendor \
    --exclude-dir=tmp \
    --exclude-dir=log \
    --exclude-dir=coverage \
    --exclude="*.lock" \
    --exclude="*.log" \
    | grep -v ".ruby-version" \
    | grep -v ".tool-versions" \
    | grep -v "Dockerfile" \
    | grep -v ".standard.yml" \
    | grep -v 'ruby file: ".ruby-version"' \
    | grep -v "ruby_version: $RUBY_VERSION" \
    | grep -v "ARG RUBY_VERSION=$RUBY_VERSION" \
    | grep -v "# Make sure RUBY_VERSION matches" \
    | grep -v "twilio-ruby" \
    | grep -v "sentry-ruby" \
    | grep -v "$0" \
    || true)

if [ -n "$HARDCODED_VERSIONS" ]; then
    echo "WARNING: Found potential hardcoded Ruby versions:"
    echo "$HARDCODED_VERSIONS"
    echo ""
    echo "Please verify these are intentional or update them to reference .ruby-version"
fi

# Final result
if [ $ERRORS -eq 0 ]; then
    echo "✅ All Ruby versions are consistent with .ruby-version ($RUBY_VERSION)"
    exit 0
else
    echo "❌ Found $ERRORS Ruby version inconsistencies!"
    echo ""
    echo "To fix these issues:"
    echo "1. Update .tool-versions to: ruby $RUBY_VERSION"
    echo "2. Update Dockerfile ARG to: ARG RUBY_VERSION=$RUBY_VERSION"
    echo "3. Ensure Gemfile uses: ruby file: \".ruby-version\""
    echo "4. Update .standard.yml to: ruby_version: $RUBY_VERSION"
    exit 1
fi
