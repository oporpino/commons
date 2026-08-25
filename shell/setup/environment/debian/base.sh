#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
  libpq5 \
  ca-certificates \
  tzdata \
  curl
rm -rf /var/lib/apt/lists/*
