#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
  vim \
  tmux \
  git \
  zsh
rm -rf /var/lib/apt/lists/*
