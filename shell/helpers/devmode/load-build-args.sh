#!/usr/bin/env bash

set -euo pipefail

project_dir="${PROJECT_DIR:-$(pwd)}"
build_args_file="${project_dir}/.infra/build-args"

[ -f "$build_args_file" ] || exit 0

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    "#"*|"") continue ;;
    *=*)
      key="${line%%=*}"
      value="${line#*=}"
      printf 'export %s=%q\n' "$key" "$value"
      ;;
  esac
done < "$build_args_file"
