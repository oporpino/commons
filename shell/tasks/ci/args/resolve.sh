#!/bin/sh
# Resolves docker build config from .infra/build-args and writes to GITHUB_OUTPUT.
#
# .infra/build-args format (lines starting with # and blank lines are ignored):
#   DOCKERFILE=${COMMONS_DIR}/docker/Dockerfile  # optional, defaults to ./Dockerfile
#   STACK=ruby
#   STACK_VERSION=3.4.4
#   DISTRO=alpine
#   DEPS_PATH=/usr/local/bundle
#   LOCK_FILES=Gemfile Gemfile.lock .ruby-version

set -eu

DOCKERFILE="./Dockerfile"
BUILD_ARGS=""
LOCK_FILES=""
STACK=""
STACK_VERSION=""
DISTRO="alpine"

if [ -f .infra/build-args ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "#"*|"") continue ;;
      DOCKERFILE=*) DOCKERFILE="$(echo "${line#DOCKERFILE=}" | envsubst)" ;;
      LOCK_FILES=*) LOCK_FILES="${line#LOCK_FILES=}" ;;
      STACK=*) STACK="${line#STACK=}"; BUILD_ARGS="${BUILD_ARGS}${line}
" ;;
      STACK_VERSION=*) STACK_VERSION="${line#STACK_VERSION=}"; BUILD_ARGS="${BUILD_ARGS}${line}
" ;;
      DISTRO=*) DISTRO="${line#DISTRO=}"; BUILD_ARGS="${BUILD_ARGS}${line}
" ;;
      *) BUILD_ARGS="${BUILD_ARGS}${line}
" ;;
    esac
  done < .infra/build-args
fi

# Create .lockfiles/ directory with lockfile copies for Docker build context
LOCKFILES_DIR=".lockfiles"
rm -rf "$LOCKFILES_DIR"
mkdir -p "$LOCKFILES_DIR"

if [ -n "$LOCK_FILES" ]; then
  for f in $LOCK_FILES; do
    if [ -f "$f" ]; then
      dir="$(dirname "$f")"
      [ "$dir" != "." ] && mkdir -p "$LOCKFILES_DIR/$dir"
      cp "$f" "$LOCKFILES_DIR/$f"
    fi
  done
fi

echo "dockerfile=${DOCKERFILE}" >> "$GITHUB_OUTPUT"
echo "stack=${STACK}" >> "$GITHUB_OUTPUT"
echo "stack_version=${STACK_VERSION}" >> "$GITHUB_OUTPUT"
echo "distro=${DISTRO}" >> "$GITHUB_OUTPUT"
printf 'build_args<<EOF\n%sEOF\n' "$BUILD_ARGS" >> "$GITHUB_OUTPUT"
