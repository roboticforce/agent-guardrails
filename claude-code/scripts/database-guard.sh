#!/bin/bash
# database-guard.sh - Block destructive database commands
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

# All patterns matched case-insensitively via grep -i below
BLOCKED_PATTERNS=(
  "drop database"
  "drop table"
  "drop schema"
  "truncate"
  "delete from.*where 1"
  "delete from.*without"
  "dropdb"
  "mysql.*-e.*drop"
  "psql.*drop"
  "mongosh.*dropDatabase"
  "mongosh.*db\.drop"
  "redis-cli.*flushall"
  "redis-cli.*flushdb"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if printf '%s\n' "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED by agent-guardrails: Destructive database command detected." >&2
    echo "" >&2
    echo "  Command: $COMMAND" >&2
    echo "  Pattern: $pattern" >&2
    echo "" >&2
    echo "Database destruction commands must be run manually by a human." >&2
    echo "See: https://github.com/roboticforce/agent-guardrails" >&2
    exit 2
  fi
done

exit 0
