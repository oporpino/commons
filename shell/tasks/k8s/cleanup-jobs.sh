#!/bin/bash
set -e

NAMESPACE="${1:?Usage: cleanup-jobs.sh <namespace>}"

kubectl get jobs -n "${NAMESPACE}" -o json 2>/dev/null \
  | python3 -c "
import json, sys
jobs = json.load(sys.stdin)
to_delete = [
  j['metadata']['name']
  for j in jobs.get('items', [])
  if (
    j.get('status', {}).get('completionTime') is not None
    or (
      j.get('status', {}).get('failed', 0) > 0
      and not j.get('status', {}).get('active', 0)
    )
  )
]
print('\n'.join(to_delete))
" \
  | xargs -r kubectl delete job -n "${NAMESPACE}" --ignore-not-found=true
