#!/bin/bash
#
# Login to ghcr.io via GitHub CLI token.
# Requires gh authenticated with read:packages scope.
#

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }

if ! command -v gh &> /dev/null; then
    warn "gh not installed, skipping ghcr.io login"
    exit 0
fi

if ! gh auth status &> /dev/null; then
    fail "gh not authenticated. Run: gh auth login"
    exit 1
fi

# Ensure read:packages scope — prompts browser if needed
if ! gh auth token | docker login ghcr.io -u "$(gh api user --jq .login)" --password-stdin &> /dev/null; then
    warn "ghcr.io login failed, refreshing token scopes..."
    gh auth refresh --scopes read:packages
    if gh auth token | docker login ghcr.io -u "$(gh api user --jq .login)" --password-stdin &> /dev/null; then
        step "ghcr.io login successful"
    else
        fail "Could not log in to ghcr.io. Ensure your account is a member of the organization."
        exit 1
    fi
else
    step "ghcr.io"
fi
