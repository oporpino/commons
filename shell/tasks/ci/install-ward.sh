#!/bin/bash
set -e

# 0.1.68+ preserves env var name case; older versions (0.1.65) uppercased them,
# which breaks case-sensitive TF_VAR_* names.
WARD_VERSION="${1:-0.1.68}"

curl -fsSL "https://github.com/br4zz4/ward/releases/download/v${WARD_VERSION}/ward_linux_amd64.tar.gz" \
  | tar -xz -C /usr/local/bin ward

chmod +x /usr/local/bin/ward
