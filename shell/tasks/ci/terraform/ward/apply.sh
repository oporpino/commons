#!/bin/bash
set -e

# Usage: apply.sh <environment> <ward_path>
# Runs terraform apply for the given workspace with secrets injected by ward.
#
#   <environment>  terraform workspace (staging | production)
#   <ward_path>    ward dot-path base; the workspace is appended
#                  (e.g. "marketing.automation" -> "marketing.automation.staging")
#
# Requires WARD_KEY in the environment (ward reads it instead of .ward/.key).
# The vault must provide the backend credentials and any TF_VAR_* the stack needs.

ENVIRONMENT="${1:?Usage: apply.sh <environment> <ward_path>}"
WARD_PATH="${2:?Usage: apply.sh <environment> <ward_path>}"

cd .infra/terraform

ward exec "${WARD_PATH}.${ENVIRONMENT}" -- terraform init

ward exec "${WARD_PATH}.${ENVIRONMENT}" -- terraform workspace select "${ENVIRONMENT}" 2>/dev/null \
  || ward exec "${WARD_PATH}.${ENVIRONMENT}" -- terraform workspace new "${ENVIRONMENT}"

ward exec "${WARD_PATH}.${ENVIRONMENT}" -- terraform apply -auto-approve
