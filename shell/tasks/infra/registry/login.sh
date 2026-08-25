#!/bin/bash
set -euo pipefail

_SSO_SESSION="wehive"
_SSO_REGION="us-east-1"
_ECR_REGISTRY="616795656532.dkr.ecr.us-east-1.amazonaws.com"
_PROFILE="wehive-ecr"
_AWS_CONFIG="${HOME}/.aws/config"

_profile_configured() {
  grep -q "\[profile ${_PROFILE}\]" "${_AWS_CONFIG}" 2>/dev/null
}

if ! _profile_configured; then
  echo ""
  echo "  ✗ AWS profile '${_PROFILE}' not found in ~/.aws/config"
  echo "  Run the bootstrap setup first:"
  echo "  gh api repos/ibft-corp/bootstrap/contents/environment/init.sh --jq '.content' | base64 -d | bash"
  echo ""
  exit 1
fi

# Remove cached access tokens so aws sso login writes a fresh one
/usr/bin/python3 -c "
import json, os, glob
cache_dir = os.path.expanduser('~/.aws/sso/cache')
for path in glob.glob(os.path.join(cache_dir, '*.json')):
    try:
        with open(path) as f:
            d = json.load(f)
        if 'accessToken' in d:
            os.remove(path)
    except Exception:
        pass
" 2>/dev/null || true

aws sso login --sso-session "${_SSO_SESSION}"

aws ecr get-login-password \
  --region "${_SSO_REGION}" \
  --profile "${_PROFILE}" \
  | docker login \
      --username AWS \
      --password-stdin \
      "${_ECR_REGISTRY}"
