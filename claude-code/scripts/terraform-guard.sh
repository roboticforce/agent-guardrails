#!/bin/bash
# terraform-guard.sh - Block destructive Terraform commands
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
  "terraform destroy"
  "terraform apply -auto-approve"
  "terraform apply --auto-approve"
  "terraform state rm"
  "terraform state push"
  "terraform force-unlock"
  "terraform import.*--allow-missing"
  "tofu destroy"
  "tofu apply -auto-approve"
  "tofu apply --auto-approve"
  "tofu state rm"
  "tofu state push"
  "terragrunt destroy"
  "terragrunt apply -auto-approve"
  "pulumi destroy"
  "pulumi destroy --yes"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if printf '%s\n' "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED by agent-guardrails: Terraform/IaC destructive command detected." >&2
    echo "" >&2
    echo "  Command: $COMMAND" >&2
    echo "  Pattern: $pattern" >&2
    echo "" >&2
    echo "Destructive infrastructure commands must be run manually by a human." >&2
    echo "See: https://github.com/roboticforce/agent-guardrails" >&2
    exit 2
  fi
done

exit 0
