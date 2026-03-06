#!/bin/bash
# git-guard.sh - Block destructive git commands
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
  "git push --force origin main"
  "git push --force origin master"
  "git push --force origin production"
  "git push -f origin main"
  "git push -f origin master"
  "git push -f origin production"
  "git push.*--force-with-lease.*main"
  "git push.*--force-with-lease.*master"
  "git push.*--force-with-lease.*production"
  "git reset --hard"
  "git clean -fd"
  "git clean -fx"
  "git checkout -- \."
  "git branch -D main"
  "git branch -D master"
  "git branch -D production"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if printf '%s\n' "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED by agent-guardrails: Destructive git command detected." >&2
    echo "" >&2
    echo "  Command: $COMMAND" >&2
    echo "  Pattern: $pattern" >&2
    echo "" >&2
    echo "Destructive git operations must be run manually by a human." >&2
    echo "See: https://github.com/roboticforce/agent-guardrails" >&2
    exit 2
  fi
done

exit 0
