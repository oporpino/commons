#!/bin/bash
set -e

# Usage: plan.sh <environment> <ward_path>
# Runs terraform plan for the given workspace with secrets injected by ward.
# See apply.sh in this directory for argument details.

ENVIRONMENT="${1:?Usage: plan.sh <environment> <ward_path>}"
WARD_PATH="${2:?Usage: plan.sh <environment> <ward_path>}"

cd .infra/terraform

export TF_WORKSPACE="${ENVIRONMENT}"

ward exec "${WARD_PATH}.${ENVIRONMENT}" -- terraform init
ward exec "${WARD_PATH}.${ENVIRONMENT}" -- terraform plan
