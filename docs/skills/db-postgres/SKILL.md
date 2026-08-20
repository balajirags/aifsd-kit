---
name: db-postgres
description: "Flyway-style PostgreSQL migration conventions: expand-migrate-contract, concurrent indexes, safe NOT NULL rollout"
---

# Database (PostgreSQL)

> Adapted from `.agents/skills/flyway-migrations/SKILL.md`. Assumes Flyway-style versioned migrations against PostgreSQL; adjust the naming pattern if this project uses a different migration tool.

## Rules

1. One change per migration file, named `V<yyyyMMddHHmm>__<short_kebab_title>.sql` (UTC timestamp for ordering) — never bundle unrelated schema changes into one migration.
2. For a non-backward-compatible change (dropping/renaming a column the running code still reads), use expand → migrate → contract across separate migrations — never drop or rename a column used by currently-deployed code in the same migration.
3. Create indexes `CONCURRENTLY`, and never inside the same transaction as other DDL — a blocking index build locks writes on a live table.
4. Add a new `NOT NULL` constraint as: add nullable column → backfill in batches → set `NOT NULL` in a later migration. Never add `NOT NULL` directly to a column on an existing populated table.
5. Add foreign keys as `NOT VALID` then `VALIDATE CONSTRAINT` in a follow-up step — never add a validated FK directly on a large existing table (it takes a full table scan under lock).
6. Backfill data in small batches (e.g. paginate by PK, a few thousand rows at a time), updating only rows where the target is still `NULL` — makes the migration idempotent and re-runnable if interrupted.
7. Seed/reference data DML must be idempotent: `INSERT ... ON CONFLICT ... DO UPDATE`, keyed by a natural key — never a bare `INSERT` that fails or duplicates on re-run.
8. Prefer `UUID` for surrogate keys, `NUMERIC` for money (never `FLOAT`/`DOUBLE`), `TIMESTAMPTZ` for timestamps, `JSONB` for schemaless data.
9. Name constraints predictably: `pk_<table>`, `fk_<from>__<to>__<column>`, `uq_<table>__<columns>`, `idx_<table>__<columns>`, `ck_<table>__<rule>` — never leave a constraint on its auto-generated name.
10. Every query touching this project's data layer uses parameterized queries or an ORM/query builder — never string-concatenated SQL with interpolated values.

## Anti-patterns

- `ALTER TABLE x ADD COLUMN y NOT NULL;` on a table with existing rows — fails outright, or if it has a default, rewrites the whole table under an `ACCESS EXCLUSIVE` lock.
- `CREATE INDEX idx_foo ON bar(col);` on a large live table without `CONCURRENTLY` — blocks writes for the duration of the build.
- Dropping a column in the same migration/release that removes the last code reading it — any rollback of the app leaves code reading a column that no longer exists.
- A seed-data migration using plain `INSERT` — fails on every re-run in a fresh environment or CI that re-applies migrations.
- Building a query by string concatenation with a variable spliced in — SQL injection, full stop.

## Examples

**Add a required column safely (expand → backfill → enforce):**
```sql
-- V202601150900__add_priority_to_orders.sql
ALTER TABLE orders ADD COLUMN priority TEXT;

-- V202601151000__backfill_orders_priority.sql
UPDATE orders SET priority = 'NORMAL' WHERE priority IS NULL;

-- V202601160900__enforce_orders_priority_not_null.sql (later release)
ALTER TABLE orders ALTER COLUMN priority SET NOT NULL;
```

**Foreign key without a blocking table scan:**
```sql
ALTER TABLE line_items ADD CONSTRAINT fk_line_items__orders__order_id
  FOREIGN KEY (order_id) REFERENCES orders(id) NOT VALID;
ALTER TABLE line_items VALIDATE CONSTRAINT fk_line_items__orders__order_id;
```
