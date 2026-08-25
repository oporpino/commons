#!/usr/bin/env bash
set -euo pipefail

DISTRO="${DISTRO:-alpine}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for pair in "ruby:ruby" "elixir:elixir" "nodejs:node"; do
  tool="${pair%:*}"; stack="${pair#*:}"
  version=
  if [ -f ".infra/build-args" ]; then
    build_stack=$(grep "^STACK=" .infra/build-args | cut -d= -f2)
    [ "$build_stack" = "$stack" ] && version=$(grep "^STACK_VERSION=" .infra/build-args | cut -d= -f2)
  fi
  [ -z "$version" ] && version=$(grep "^$tool " .tool-versions 2>/dev/null | awk '{print $2}')
  [ -z "$version" ] && continue
  STACK="$stack" STACK_VERSION="$version" DISTRO="$DISTRO" bash "$SCRIPT_DIR/push.sh"
done
