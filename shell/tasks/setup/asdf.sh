#!/bin/bash
#
# ASDF Stack Setup
# Installs plugins and language versions defined in .tool-versions.
# Assumes asdf is already installed (run environment/init/asdf.sh first).
#

set -euo pipefail

skip() { echo -e "  \033[0;90m–\033[0m $1"; }

asdf_tool_installed() {
  local tool="$1" version="$2"

  asdf plugin list 2>/dev/null | grep -qx "^${tool}$" || return 1
  asdf where "$tool" "$version" >/dev/null 2>&1
}

asdf_stack_ready() {
  if ! command -v asdf &> /dev/null; then
    return 1
  fi

  [ -f ".tool-versions" ] || return 0

  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^#.*$ ]] && continue

    tool=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | awk '{print $2}')

    asdf_tool_installed "$tool" "$version" || return 1
  done < .tool-versions

  return 0
}

asdf_stack_install() {
  if ! command -v asdf &> /dev/null; then
    echo -e "  \033[0;31m✗\033[0m asdf not found — run environment setup first"
    exit 1
  fi

  if [ ! -f ".tool-versions" ]; then
    skip "asdf (no .tool-versions)"
    exit 0
  fi

  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^#.*$ ]] && continue

    tool=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | awk '{print $2}')

    if ! asdf plugin list 2>/dev/null | grep -qx "^${tool}$"; then
      asdf plugin add "$tool" > /dev/null 2>&1
    fi

    if ! asdf where "$tool" "$version" >/dev/null 2>&1; then
      _asdf_err=$(asdf install "$tool" "$version" 2>&1) || {
        _asdf_bad_dir=$(echo "$_asdf_err" | grep -o "destination path '[^']*'" | sed "s/destination path '//;s/'$//" || true)
        if [ -n "$_asdf_bad_dir" ]; then
          rm -rf "$_asdf_bad_dir"
          asdf install "$tool" "$version"
        else
          echo "$_asdf_err" >&2
          exit 1
        fi
      }
    fi
  done < .tool-versions

  asdf reshim
}

if [ "${1:-}" = "--check" ]; then
  asdf_stack_ready
  exit $?
fi

asdf_stack_install
