#!/bin/bash
# database-guard.sh - Block destructive database commands
# Exit 0 = allow, Exit 2 = block (message shown to user)

INPUT=$(cat -)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

BLOCKED_PATTERNS=(
  "DROP DATABASE"
  "DROP TABLE"
  "DROP SCHEMA"
  "TRUNCATE"
  "DELETE FROM.*WHERE 1"
  "DELETE FROM.*WITHOUT"
  "drop database"
  "drop table"
  "drop schema"
  "truncate"
  "dropdb"
  "mysql.*-e.*drop"
  "psql.*DROP"
  "psql.*drop"
  "mongosh.*dropDatabase"
  "mongosh.*db\.drop"
  "redis-cli.*FLUSHALL"
  "redis-cli.*FLUSHDB"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
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
