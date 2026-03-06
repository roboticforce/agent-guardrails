#!/bin/bash
# kubernetes-guard.sh - Block destructive Kubernetes commands
# Exit 0 = allow, Exit 2 = block (message shown to user)
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "BLOCKED: jq is required for agent-guardrails but not installed." >&2
  echo "Install jq: https://jqlang.github.io/jq/download/" >&2
  exit 2
fi

INPUT=$(cat -)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

BLOCKED_PATTERNS=(
  "kubectl delete namespace"
  "kubectl delete ns "
  "kubectl delete -f "
  "kubectl delete --all"
  "kubectl drain.*--force"
  "kubectl drain.*--delete-emptydir-data"
  "kubectl cordon"
  "kubectl delete deployment.*--all"
  "kubectl delete pods.*--all"
  "kubectl delete svc.*--all"
  "kubectl delete pvc.*--all"
  "kubectl delete pv.*--all"
  "helm uninstall"
  "helm delete"
  "helm del "
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if printf '%s\n' "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED by agent-guardrails: Destructive Kubernetes command detected." >&2
    echo "" >&2
    echo "  Command: $COMMAND" >&2
    echo "  Pattern: $pattern" >&2
    echo "" >&2
    echo "Kubernetes destructive commands must be run manually by a human." >&2
    echo "See: https://github.com/roboticforce/agent-guardrails" >&2
    exit 2
  fi
done

exit 0
