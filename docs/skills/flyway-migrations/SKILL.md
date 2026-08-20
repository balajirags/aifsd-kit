---
name: flyway-migrations
description: How to write safe, zero-downtime Flyway migrations for PostgreSQL with proper naming, expand/contract patterns, and idempotent DML.
---

# Flyway Migration Best Practices (PostgreSQL)

> Purpose: Generate safe, zero‑downtime‑friendly Flyway migrations and companion DDL/DML scripts with strong conventions.

---

## Conventions & Best Practices

* **Versioned migrations**: `V⟪yyyyMMddHHmm⟫__⟪short_kebab_title⟫.sql` (UTC timestamp for ordering). One change per file.
* **Repeatable migrations**: `R__⟪object⟫.sql` only for views/functions/materialized views; include `-- checksum:` marker.
* **Schema**: default `public` unless otherwise specified.
* **Idempotency**: Use `IF NOT EXISTS` / `IF EXISTS` where safe. For destructive changes use expand‑migrate‑contract pattern.

---

## Zero Downtime (Expand/Contract)

1. **Expand**: add new tables/columns/indexes concurrently, allow nulls.
2. **Migrate data** in batches; backfill using stable keys, no exclusive locks.
3. **Switch traffic** (app release uses new structures).
4. **Contract**: drop old columns/indexes in a separate migration.

---

## Index Rules

* Create `CONCURRENTLY` when possible; never inside a transaction.
* Use a separate migration if needed.

---

## Constraint Rules

* Add with `NOT VALID`, then `VALIDATE CONSTRAINT` to avoid table scans and long locks.
* Defaults: prefer setting default first, then backfill, then make `NOT NULL`.

---

## Audit Columns

* `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`
* `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`
* Use triggers only if required.

---

## Naming Conventions

| Object | Pattern |
|---|---|
| PK | `pk_<table>` |
| FK | `fk_<from_table>__<to_table>__<column>` |
| Unique | `uq_<table>__<columns>` |
| Index | `idx_<table>__<columns>` |
| Check | `ck_<table>__<rule>` |

---

## Data Type Preferences

* `UUID` for surrogate keys
* `NUMERIC(19,2)` for money
* `JSONB` for schemaless blobs
* `TEXT` over varying small varchar

---

## Seed / Reference Data

* DML must be idempotent using `INSERT ... ON CONFLICT ... DO UPDATE`.
* Use natural keys, not surrogate IDs; avoid hard-coded UUIDs unless stable.

---

## Safety Rules

* Never drop or rename columns used by running code in the same deploy.
* Use shadow columns + backfill + application switch.

---

## Common Patterns

### Add Column Safely (Expand Phase)

1. Add nullable column with default if applicable.
2. If default required, set default first, backfill in batches, then set `NOT NULL`.
3. Create indexes `CONCURRENTLY` in a separate non-transactional block.

### Backfill in Batches (Idempotent DML)

* Use PK pagination with small batches (e.g., 5k rows).
* Update only rows where target column `IS NULL` to be idempotent.
* Use `pg_sleep(0.01)` between batches.

### Safe Column Rename (Shadow + Swap)

1. **Expand**: `ADD COLUMN` new_col, backfill from old_col in batches, update app to use new_col.
2. **Contract**: Drop old_col in a later migration once unused.
3. Optional trigger to keep cols in sync during rollout.

### Foreign Key Without Full Table Lock

1. `ADD CONSTRAINT ... FOREIGN KEY ... NOT VALID;`
2. `VALIDATE CONSTRAINT ...;`

### JSONB Column with GIN Index

1. `ADD COLUMN ... JSONB NOT NULL DEFAULT '{}'::jsonb;`
2. `CREATE INDEX CONCURRENTLY ... USING GIN (... jsonb_path_ops);`

### Enum Pattern (Lookup Table)

* Create lookup table with `code TEXT PRIMARY KEY`.
* Seed with `ON CONFLICT` upsert.
* Add FK from source table to enum table (`NOT VALID` + `VALIDATE`).
