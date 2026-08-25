#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
  build-essential
rm -rf /var/lib/apt/lists/*
