#!/bin/sh -e

if [ "${SETUP_CONTEXT:-local}" = "docker" ]; then
  printf 'BUNDLE_PATH=/usr/local/bundle\n' >> /source/.build-env
fi
