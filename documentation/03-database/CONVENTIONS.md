# DATABASE CONVENTIONS

**Document tier:** 3 — Database
**Status:** Active

Stated once here; **not repeated in each table specification**. Every table in [`tables/`](tables/) follows these unless it explicitly documents a deviation and why.

---

## Naming

| Object | Convention | Example |
|---|---|---|
| Table | `snake_case`, plural | `boarding_events` |
| Column | `snake_case` | `boarded_at` |
| Primary key | `id` | |
| Foreign key | `<referenced_singular>_id` | `student_id` |
| Index | `idx_<table>_<columns>` | `idx_students_tenant_school` |
| Unique constraint | `uq_<table>_<columns>` | `uq_students_tenant_admission_no` |
| Check constraint | `ck_<table>_<rule>` | `ck_trips_status_valid` |
| Foreign key constraint | `fk_<table>_<referenced>` | `fk_trips_vehicle` |
| Partition | `<table>_<yyyy_mm_dd>` | `position_history_2026_08_03` |

Reserved words are never used as identifiers. Boolean columns read as assertions: `is_active`, `has_attendant`.

---

## Standard Columns

### Every tenant-scoped table

```sql
id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
tenant_id    UUID        NOT NULL REFERENCES organizations(id),
created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
created_by   UUID,
updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
updated_by   UUID,
version      BIGINT      NOT NULL DEFAULT 0
```

- **UUID primary keys.** Sequential integers would leak tenant volume across a shared schema and make identifiers guessable.
- **`tenant_id` is the organization ID**, always ([`MULTI_TENANCY.md`](../02-system-design/MULTI_TENANCY.md)). Never the school ID.
- **`version`** drives JPA optimistic locking. Concurrent edits fail rather than silently overwrite.
- **`created_by` / `updated_by`** are nullable — system-generated rows have no user actor.

### Soft delete, where applicable

```sql
is_active    BOOLEAN     NOT NULL DEFAULT true,
deleted_at   TIMESTAMPTZ,
deleted_by   UUID
```

**Safety and audit tables have no soft delete and no delete path at all** (BR-AUD-001, BR-BOARD-001). Corrections are compensating records.

---

## Types

| Use | Type | Reason |
|---|---|---|
| Identifier | `UUID` | See above |
| Timestamp | `TIMESTAMPTZ` | Always. Never `TIMESTAMP`. |
| Date without time | `DATE` | Trip service date |
| Time of day | `TIME` | Scheduled stop times |
| Money | `NUMERIC(19,4)` | Never floating point |
| Coordinates | `NUMERIC(9,6)` lat / `NUMERIC(9,6)` lon | Sufficient precision; exact comparison |
| Distance, speed | `NUMERIC` in SI units — metres, m/s | Conversion happens at display |
| Enum | `VARCHAR` + `CHECK` constraint | Not native `ENUM` — altering one requires locks and migration pain |
| Free text | `TEXT` | No arbitrary `VARCHAR(n)` limits |
| Structured extension | `JSONB` | Sparingly; never for anything queried in a hot path or governed by a business rule |

### Time handling

**All timestamps are stored in UTC** (`TIMESTAMPTZ`) and displayed in the school's configured time zone (BR-CFG-006). The school's time zone is data.

Offline-recorded safety events carry two timestamps (ADR-0008, BR-BOARD-008):

```sql
occurred_at        TIMESTAMPTZ NOT NULL,  -- device clock
recorded_at        TIMESTAMPTZ NOT NULL,  -- server receipt
clock_skew_seconds INTEGER                -- measured at sync
```

Reports use `occurred_at`. Investigations can see both. **The device clock is never treated as authoritative.**

---

## Constraints

Constraints belong in the database, not only in application code. An application bug should hit a constraint, not corrupt data.

- `NOT NULL` wherever the domain requires a value.
- Foreign keys always declared, with explicit `ON DELETE` behaviour — `RESTRICT` by default. `CASCADE` is used only where the child has no meaning without the parent, and never on a table holding safety records.
- Enum-like columns always carry a `CHECK` constraint listing valid values.
- Unique constraints include `tenant_id` where uniqueness is per-tenant: `UNIQUE (tenant_id, school_id, admission_no)`.
- Domain invariants expressible in SQL are expressed in SQL — a stop sequence must be positive, a geofence radius must fall within platform bounds (BR-ROUTE-003).

---

## Row-Level Security

Every tenant-scoped table (ADR-0001):

```sql
ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;
ALTER TABLE <table> FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON <table>
    USING      (tenant_id = current_setting('app.tenant_id', true)::uuid)
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::uuid);
```

Both `USING` and `WITH CHECK` are mandatory — `USING` alone protects reads but permits writing a row into another tenant. Full detail and rationale: [`RLS_POLICIES.md`](RLS_POLICIES.md).

A migration adding a table with a `tenant_id` column but no forced RLS policy **fails the build**.

---

## Indexing

Every tenant-scoped index leads with `tenant_id` — the RLS predicate applies to every query.

```sql
CREATE INDEX idx_students_tenant_school ON students (tenant_id, school_id);
```

Index foreign keys used in joins. Partial indexes for common filtered queries:

```sql
CREATE INDEX idx_trips_active ON trips (tenant_id, status)
    WHERE status IN ('STARTED', 'IN_PROGRESS');
```

See [`INDEXING_AND_PARTITIONING.md`](INDEXING_AND_PARTITIONING.md).

---

## Append-Only Tables

`audit_records`, `data_access_records`, `boarding_events`, `handovers`, `sos_alerts`.

Enforced by **grants, not convention**:

```sql
GRANT INSERT, SELECT ON boarding_events TO guardian_app;
-- no UPDATE, no DELETE
```

A trigger additionally rejects `UPDATE` and `DELETE`. Two controls because this is the property the platform's evidentiary value rests on.

---

## Migrations

Flyway, versioned, forward-only. See [`MIGRATION_STRATEGY.md`](MIGRATION_STRATEGY.md).

Never edit an applied migration. Never write a destructive migration without an expand-contract sequence. Every migration is tested against a database seeded with realistic data before it reaches production.

---

## Ownership

Each table is owned by exactly one module ([`MODULE_MAP.md`](../01-product-discovery/MODULE_MAP.md) cross-module rule 1). Cross-module reads go through the owning module's application layer, never by querying its tables directly.

The table specification in [`tables/`](tables/) names the owning module.

---

## What Does Not Go in the Database

- Business logic in triggers, beyond integrity enforcement. Rules live in the domain, once (BR: [`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §6).
- Stored procedures for application behaviour.
- Configuration that belongs in the typed configuration registry (MOD-17).
- User-facing text — localised resource keys only (BR-CFG-005).
