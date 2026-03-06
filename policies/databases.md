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

## What agents CAN do safely

- `SELECT` queries (read-only)
- `INSERT` with specific values
- `UPDATE` with specific `WHERE` clauses
- `CREATE TABLE` / `CREATE INDEX`
- `ALTER TABLE` (additive changes only)
- `pg_dump` / `mysqldump` (backups)
- `\dt`, `\d+`, `SHOW TABLES` (inspection)

## Recommended protections beyond guardrails

- Use read-only database users for agent connections
- Enable `deletion_protection` on managed database instances (RDS, Cloud SQL, etc.)
- Maintain backups independent of infrastructure lifecycle (Terraform can delete snapshots)
- Test backup restoration regularly - untested backups are not backups
