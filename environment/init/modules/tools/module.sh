#!/usr/bin/env bash
# Module: tools
# Installs common development tools

_tools_print() {
    echo "│  $*"
}

_tools_check() {
    local tool="$1"
    if command -v "$tool" &>/dev/null; then
        _tools_print "✓ $tool $(command -v "$tool" | head -1)"
        return 0
    else
        _tools_print "✗ $tool not found"
        return 1
    fi
}

_tools_brew_install() {
    local package="$1"
    if brew list "$package" &>/dev/null 2>&1; then
        _tools_print "✓ $package already installed"
    else
        _tools_print "  Installing $package..."
        brew install "$package" --quiet 2>/dev/null && \
            _tools_print "✓ $package installed" || \
            _tools_print "✗ Failed to install $package"
    fi
}

_tools_print "Checking development tools..."

# Homebrew (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
        _tools_print "  Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>/dev/null
    else
        _tools_print "✓ brew $(brew --version | head -1)"
    fi

    BREW_TOOLS=(git jq make curl wget)
    for tool in "${BREW_TOOLS[@]}"; do
        _tools_brew_install "$tool"
    done
fi

# Docker
if ! _tools_check "docker"; then
    _tools_print "  → Install Docker Desktop from https://www.docker.com/products/docker-desktop"
fi

_tools_print "Done."
