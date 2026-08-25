#!/bin/bash
#
# Shared setup helpers.
#

_spin() {
  local message="$1"
  shift
  local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  local pid rc char tmp

  tmp="$(mktemp "${TMPDIR:-/tmp}/setup-spin.XXXXXX")"
  "$@" >"$tmp" 2>&1 &
  pid=$!

  trap 'kill "$pid" >/dev/null 2>&1 || true' INT TERM
  trap 'rm -f "$tmp"' RETURN

  while kill -0 "$pid" >/dev/null 2>&1; do
    char=$(printf '%s' "$spinner" | cut -c $(( (i % 10) + 1 )))
    printf '\r[%s] %s' "$char" "$message"
    i=$((i + 1))
    sleep 0.1
  done

  wait "$pid"
  rc=$?

  trap - INT TERM
  if [ "$rc" -ne 0 ]; then
    cat "$tmp" >&2
  fi
  printf '\r\033[K'
  rm -f "$tmp"
  trap - RETURN
  return "$rc"
}

setup_step() {
  local label="$1"
  shift

  if _spin "$label" "$@"; then
    printf "  ✔ %s\n" "$label"
  fi
}

setup_step_if_cmd() {
  local label="$1"
  local check_cmd="$2"
  shift 2

  if eval "$check_cmd"; then
    printf "  ✔ %s\n" "$label"
  else
    setup_step "$label" "$@"
  fi
}

setup_project_header() {
  local label="$1"
  local line="────────────────────────────────────────────────────"
  echo "╭─ ${label}"
  echo "╰${line}"
}

setup_section() {
  printf "  %s\n" "$1"
}
