#!/usr/bin/env bash
# Module: claude
# Installs and configures Claude Code

_claude_print() {
    echo "│  $*"
}

_claude_print "Setting up Claude Code..."

# Install Claude Code CLI if not present
if command -v claude &>/dev/null; then
    _claude_print "✓ Claude Code already installed ($(claude --version 2>/dev/null || echo 'unknown version'))"
else
    _claude_print "  Installing Claude Code..."
    if command -v npm &>/dev/null; then
        npm install -g @anthropic-ai/claude-code --silent 2>/dev/null && \
            _claude_print "✓ Claude Code installed" || \
            _claude_print "✗ Failed to install Claude Code via npm"
    else
        _claude_print "✗ npm not found — install Node.js first, then run: npm install -g @anthropic-ai/claude-code"
    fi
fi

# Create project-level Claude configuration directory
CLAUDE_PROJECT_DIR="$PROJECT_DIR/.claude"
mkdir -p "$CLAUDE_PROJECT_DIR"

# Write project settings if they don't exist
CLAUDE_SETTINGS="$CLAUDE_PROJECT_DIR/settings.json"
if [ ! -f "$CLAUDE_SETTINGS" ]; then
    cat > "$CLAUDE_SETTINGS" <<'EOF'
{
  "permissions": {
    "allow": [],
    "deny": []
  }
}
EOF
    _claude_print "✓ Created $CLAUDE_SETTINGS"
else
    _claude_print "✓ $CLAUDE_SETTINGS already exists"
fi

_claude_print "Done."
