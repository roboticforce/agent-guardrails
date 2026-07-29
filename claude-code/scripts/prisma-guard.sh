#!/bin/bash
# prisma-guard.sh - Block Prisma (and other ORM) migration commands that can wipe a
# production database by way of a shadow database, a forced reset, or an explicit
# "accept data loss" flag. See examples/incidents/opus5-ultracode-database-wipe.md
# for the real-world incident this guard exists to prevent.
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

# All patterns matched case-insensitively via grep -i below.
#
# The shadow-database hazard: Prisma's migrate/diff workflow resets the shadow
# database before replaying migrations. If an agent points --shadow-database-url
# at a production connection string, that reset drops every table in prod and
# rebuilds from the migrations folder - which may be stale (tables missing from
# the folder are dropped and never recreated). Blocking the flag outright is the
# safe call: the guard sees the literal command BEFORE shell expansion, so it
# catches the hazard without needing to know whether $DATABASE_URL_UNPOOLED
# resolves to prod. A human can still run the command by hand.
BLOCKED_PATTERNS=(
  "--shadow-database-url"
  "prisma migrate reset"
  "prisma migrate.*--force"
  "prisma db push --force-reset"
  "prisma db push --accept-data-loss"
  "prisma db push.*--accept-data-loss"
  "prisma.*--accept-data-loss"
  "rails db:drop"
  "rails db:migrate:reset"
  "rails db:setup.*DROP"
  "rake db:drop"
  "rake db:migrate:reset"
  "sequelize.*migrate:undo"
  "knex.*migrate:rollback"
  "typeorm.*schema:drop"
  "typeorm.*migration:revert"
  "alembic.*downgrade"
  "flyway.*clean"
  "flyway.*undo"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  # -- ends option parsing so patterns that start with - (e.g. --shadow-database-url)
  # are treated as the pattern, not as grep flags.
  if printf '%s\n' "$COMMAND" | grep -qiE -- "$pattern"; then
    echo "BLOCKED by agent-guardrails: Destructive migration / shadow-database command detected." >&2
    echo "" >&2
    echo "  Command: $COMMAND" >&2
    echo "  Pattern: $pattern" >&2
    echo "" >&2
    echo "Prisma --shadow-database-url, migrate reset, db push --force-reset," >&2
    echo "--accept-data-loss, and the equivalent ORM reset/drop commands can wipe a" >&2
    echo "production database. These must be run manually by a human." >&2
    echo "See: https://github.com/roboticforce/agent-guardrails" >&2
    exit 2
  fi
done

exit 0