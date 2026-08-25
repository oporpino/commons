#!/bin/bash
set -e

CLUSTER_NAME="${CLUSTER_NAME:-shared-kubernetes}"
EXPIRY="${KUBECONFIG_EXPIRY:-600}"

doctl kubernetes cluster kubeconfig save --expiry-seconds "${EXPIRY}" "${CLUSTER_NAME}"
