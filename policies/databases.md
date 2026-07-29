# Database Policy

## Blocked commands

| Pattern | Covers |
|---------|--------|
| `DROP DATABASE` | PostgreSQL, MySQL, SQL Server |
| `DROP TABLE` | All SQL databases |
| `DROP SCHEMA` | PostgreSQL, SQL Server |
| `TRUNCATE` | All SQL databases |
| `dropdb` | PostgreSQL CLI utility |
| `FLUSHALL` / `FLUSHDB` | Redis |
| `dropDatabase()` | MongoDB |

## Blocked migration / shadow-database commands

These are enforced by `prisma-guard.sh` (and the matching `settings.json` deny
rules). They are not raw SQL - they are ORM/migration-tool commands that drop
or reset a database as a side effect of "applying" or "diffing" migrations.

| Pattern | Covers |
|---------|--------|
| `--shadow-database-url` | Prisma `migrate diff` / `migrate dev` when the shadow URL is pointed at a real database. Prisma resets the shadow database before replaying migrations, so pointing it at prod drops every table and rebuilds from the migrations folder. This is the July 2026 Opus 5 ultracode incident - see `examples/incidents/opus5-ultracode-database-wipe.md`. |
| `prisma migrate reset` | Prisma - drops and recreates the database, replays all migrations, runs the seed |
| `prisma db push --force-reset` | Prisma - forces a schema reset |
| `prisma ... --accept-data-loss` | Prisma `db push` - explicitly accepts data loss |
| `rails db:drop` / `rake db:drop` | Rails - drops the database |
| `rails db:migrate:reset` / `rake db:migrate:reset` | Rails - drop + recreate + migrate |
| `flyway clean` / `flyway undo` | Flyway - drops all objects in a schema / reverts a migration |
| `alembic downgrade` | SQLAlchemy/Alembic - reverts migrations (can drop tables) |
| `sequelize migrate:undo`, `knex migrate:rollback`, `typeorm schema:drop` / `migration:revert` | Other ORM reset/drop/revert commands |

### Why the shadow-database flag is blocked outright

The guard sees the literal command string BEFORE the shell expands
environment variables. So blocking `--shadow-database-url` catches the hazard
regardless of whether `$DATABASE_URL_UNPOOLED` (or any other env var) resolves
to a production connection. The agent cannot talk its way around it by swapping
in a different env var name, and a human who genuinely needs to run a Prisma
shadow-database diff can still type the command into their own terminal.

### A limitation to know

The guard only inspects the command string. If `--shadow-database-url` is set
in `prisma.config.js` / the schema datasource block / a `.env` file rather than
passed as a CLI flag, `prisma migrate dev` can still reach a prod database
without the flag appearing in the command. The guard cannot see that. The
defense for that case is operational: never put a production connection string
in the agent's environment, and keep shadow databases on a separate
non-production URL. See "Recommended protections beyond guardrails" below.

## What agents CAN do safely

- `SELECT` queries (read-only)
- `INSERT` with specific values
- `UPDATE` with specific `WHERE` clauses
- `CREATE TABLE` / `CREATE INDEX`
- `ALTER TABLE` (additive changes only)
- `pg_dump` / `mysqldump` (backups)
- `\dt`, `\d+`, `SHOW TABLES` (inspection)
- `prisma migrate dev --name <name>` (normal additive dev migration - uses its own shadow database, not a prod URL)
- `prisma migrate status` / `prisma migrate deploy` (inspect / apply pending migrations, non-destructive)
- `rails db:migrate` (additive migration, no reset)

## Recommended protections beyond guardrails

- Use read-only database users for agent connections
- Enable `deletion_protection` on managed database instances (RDS, Cloud SQL, etc.)
- Keep production credentials out of the agent's environment entirely - the
  shadow-database guard catches the CLI flag, but it cannot catch a shadow URL
  configured in `prisma.config.js` or a `.env` file
- Maintain backups independent of infrastructure lifecycle (Terraform can delete snapshots)
- Test backup restoration regularly - untested backups are not backups
