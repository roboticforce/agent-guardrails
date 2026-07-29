# Incident: Opus 5 ultracode wipes a production database via Prisma shadow database

**Source:** [And just like that, Opus 5 ultracode wipes the prod database](https://www.reddit.com/r/Anthropic/comments/1v9iurd/and_just_like_that_opus_5_ultracode_wipes_the/) (r/Anthropic, July 2026)

**Postmortem:** [Opus 5 ultracode wiped a production database - postmortem](https://tokenstead.ai/guides/opus-5-ultracode-database-wipe-postmortem)

**Date:** July 2026

## What happened

A developer gave Claude Opus 5 (in "ultracode" mode) write access to a production
Supabase database. The agent ran:

```
prisma migrate diff --shadow-database-url=$DATABASE_URL_UNPOOLED
```

Prisma's `migrate diff` workflow resets the shadow database before replaying
migrations. Because the shadow URL was pointed at the production connection
(`$DATABASE_URL_UNPOOLED` resolved to prod), that reset dropped every table in
production and rebuilt the schema from the migrations folder.

Two tables - `BlogPost` and `ApiKey` - were never in the migrations folder (they
had been added another way), so they were dropped and never recreated. The agent
reported back: "The database has been wiped. This is my fault."

Two failures had to stack for this to happen:

1. The agent was handed production credentials (it could reach prod at all).
2. The shadow-database URL was aimed at the production connection.

Neither alone is catastrophic. Together they dropped the whole database.

## Recovery

Reconstructed from the developer's Reddit post. Recovery details are
case-specific; the general lesson is below.

## What guardrails would have prevented this

### Hard blocks (would have stopped it entirely)

A `settings.json` deny rule:
```json
"Bash(command:*--shadow-database-url*)"
"Bash(command:*prisma migrate reset*)"
"Bash(command:*prisma*--accept-data-loss*)"
```

A `prisma-guard.sh` hook matching `--shadow-database-url` and exiting with code
2.

The guard sees the literal command string BEFORE the shell expands
`$DATABASE_URL_UNPOOLED`, so it blocks the hazard without needing to know
whether that variable resolves to production. The agent cannot bypass it by
swapping in a different env var name.

### Soft protections (would have added friction)

- Keep production credentials out of the agent's environment entirely
- Configure Prisma's shadow database on a separate, non-production URL (in
  `prisma.config.js` or the schema datasource block, not as a CLI flag)
- Never point a shadow database at production - operationally, not just in policy
- `CLAUDE.md` instruction: "NEVER use --shadow-database-url; ask a human for
  migration diffs"

### A limitation the guard does not cover

The guard inspects the command string only. If `--shadow-database-url` is set in
`prisma.config.js` or a `.env` file rather than passed on the CLI, `prisma
migrate dev` can still reach a production database without the flag appearing in
the command. The guard cannot see that. Keeping prod credentials out of the
agent's environment is the defense for that case.

## Key lesson

"The AI did it" is the wrong frame. The agent did not go rogue - it was handed
production credentials and a footgun flag, and it pulled the trigger. Human
approval is not a reliable safety mechanism here because the person approving
`prisma migrate diff --shadow-database-url=...` does not necessarily realize
that "diff" resets the shadow database, or that the shadow URL points at prod.
Hard technical controls that block the flag before the shell ever sees it are
what actually stop this.