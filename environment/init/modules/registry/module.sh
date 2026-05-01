#!/usr/bin/env bash
# Module: registry
# Configures container registry access

_registry_print() {
    echo "│  $*"
}

_registry_print "Configuring container registry..."

REGISTRY_HOST="${WEHIVE_REGISTRY_HOST:-}"
REGISTRY_USER="${WEHIVE_REGISTRY_USER:-}"
REGISTRY_TOKEN="${WEHIVE_REGISTRY_TOKEN:-}"

if [ -z "$REGISTRY_HOST" ]; then
    _registry_print "⚠  WEHIVE_REGISTRY_HOST not set — skipping registry login"
    _registry_print "   Set WEHIVE_REGISTRY_HOST, WEHIVE_REGISTRY_USER, and WEHIVE_REGISTRY_TOKEN"
    _registry_print "   in your shell environment to enable automatic registry login."
else
    if ! command -v docker &>/dev/null; then
        _registry_print "✗ Docker not found — install Docker Desktop first"
    else
        if [ -n "$REGISTRY_TOKEN" ] && [ -n "$REGISTRY_USER" ]; then
            echo "$REGISTRY_TOKEN" | docker login "$REGISTRY_HOST" \
                --username "$REGISTRY_USER" --password-stdin 2>/dev/null && \
                _registry_print "✓ Logged in to $REGISTRY_HOST" || \
                _registry_print "✗ Login to $REGISTRY_HOST failed"
        else
            _registry_print "⚠  WEHIVE_REGISTRY_USER or WEHIVE_REGISTRY_TOKEN not set"
        fi
    fi
fi

_registry_print "Done."
