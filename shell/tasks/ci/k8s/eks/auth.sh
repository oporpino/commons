#!/bin/bash
set -e

# Write a self-contained kubeconfig for the shared EKS cluster in CI.
#
# Assumes the shared account's TerraformRole (which has an EKS access entry)
# using the management terraform credentials, then embeds a bearer token
# directly in the kubeconfig — no exec plugin, so it does not depend on the
# ambient AWS creds still being present when kubectl runs.
#
# Env (injected by ward in CI):
#   TF_VAR_aws_terraform_access_key_id / _secret_access_key  management user
#   TF_VAR_aws_shared_account_id                             account owning EKS
#   TF_VAR_aws_region (default us-east-1)
#   EKS_CLUSTER_NAME (default shared-kubernetes)

# The AWS creds/account come from ward. If a ward path is given as $1 and we are
# not already inside `ward exec`, re-run this script under it so the TF_VAR_*
# from the vault are present in the environment.
if [ -n "${1:-}" ] && [ -z "${WARD_EXEC:-}" ]; then
  export WARD_EXEC=1
  exec ward exec "$1" -- bash "$0"
fi

CLUSTER_NAME="${EKS_CLUSTER_NAME:-shared-kubernetes}"
REGION="${TF_VAR_aws_region:-us-east-1}"
SHARED_ACCOUNT="${TF_VAR_aws_shared_account_id:?aws_shared_account_id required}"

export AWS_ACCESS_KEY_ID="${TF_VAR_aws_terraform_access_key_id:?}"
export AWS_SECRET_ACCESS_KEY="${TF_VAR_aws_terraform_secret_access_key:?}"
unset AWS_SESSION_TOKEN

CREDS=$(aws sts assume-role \
  --role-arn "arn:aws:iam::${SHARED_ACCOUNT}:role/TerraformRole" \
  --role-session-name ci-k8s \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

export AWS_ACCESS_KEY_ID="$(echo "$CREDS" | cut -f1)"
export AWS_SECRET_ACCESS_KEY="$(echo "$CREDS" | cut -f2)"
export AWS_SESSION_TOKEN="$(echo "$CREDS" | cut -f3)"

ENDPOINT=$(aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${REGION}" \
  --query 'cluster.endpoint' --output text)
CA=$(aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${REGION}" \
  --query 'cluster.certificateAuthority.data' --output text)
TOKEN=$(aws eks get-token --cluster-name "${CLUSTER_NAME}" --region "${REGION}" \
  --query 'status.token' --output text)

mkdir -p "${HOME}/.kube"
cat > "${HOME}/.kube/config" <<EOF
apiVersion: v1
kind: Config
current-context: ${CLUSTER_NAME}
clusters:
  - name: ${CLUSTER_NAME}
    cluster:
      server: ${ENDPOINT}
      certificate-authority-data: ${CA}
contexts:
  - name: ${CLUSTER_NAME}
    context:
      cluster: ${CLUSTER_NAME}
      user: ${CLUSTER_NAME}
users:
  - name: ${CLUSTER_NAME}
    user:
      token: ${TOKEN}
EOF
