#!/usr/bin/env bash
# Source this to assume an AWS IAM role using ward-injected management creds.
# It reads TF_VAR_aws_terraform_access_key_id / _secret_access_key from the env
# (put there by `ward exec`) and exports temporary role credentials.
#
# Usage:
#   ASSUME_ROLE_ARN=arn:aws:iam::123456789012:role/TerraformRole \
#     source "$COMMONS_DIR/shell/tasks/ci/aws/assume-role.sh"
#
# Parameters (env vars):
#   ASSUME_ROLE_ARN      (required) role to assume
#   ASSUME_ROLE_SESSION  (default: TerraformSession) STS session name
#   AWS_REGION           (default: us-east-1)
set -euo pipefail

: "${ASSUME_ROLE_ARN:?ASSUME_ROLE_ARN is required}"
ASSUME_ROLE_SESSION="${ASSUME_ROLE_SESSION:-TerraformSession}"
AWS_REGION="${AWS_REGION:-us-east-1}"

export AWS_ACCESS_KEY_ID="$TF_VAR_aws_terraform_access_key_id"
export AWS_SECRET_ACCESS_KEY="$TF_VAR_aws_terraform_secret_access_key"
unset AWS_SESSION_TOKEN AWS_PROFILE

CREDS=$(aws sts assume-role \
  --role-arn "$ASSUME_ROLE_ARN" \
  --role-session-name "$ASSUME_ROLE_SESSION" \
  --region "$AWS_REGION" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | cut -f1)
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | cut -f2)
export AWS_SESSION_TOKEN=$(echo "$CREDS" | cut -f3)
