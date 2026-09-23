# MOD-09 — Boarding & Handover Tables 🔒

**Owning module:** `com.guardian.boarding` · **Rules:** BR-BOARD-*, BR-HAND-*, BR-SAFE-001

**The most safety-critical tables in the platform.** All four are **append-only** — enforced by grants and triggers, not convention ([`CONVENTIONS.md`](../CONVENTIONS.md)).

```sql
GRANT INSERT, SELECT ON boarding_events, handovers,
                        reconciliations, reconciliation_items TO guardian_app;
-- no UPDATE, no DELETE granted
```

`reconciliations` and `reconciliation_items` are the one qualified exception: resolution fields are set once via a controlled path (see below).

---

## `boarding_events`

An immutable record that a student boarded or alighted.

| Column | Type | Notes |
|---|---|---|
| `trip_id` | `UUID` | `NOT NULL` → `trips` |
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `stop_id` | `UUID` | → `stops`. Null when boarding at school. |
| `event_type` | `VARCHAR(16)` | `NOT NULL`, `BOARD` / `ALIGHT` |
| `verification_method` | `VARCHAR(32)` | `NOT NULL`, `QR_SCAN` / `CARD` / `MANUAL` / `OTP` / `VISUAL` |
| `actor_id` | `UUID` | `NOT NULL` — the staff member who recorded it |
| `actor_role` | `VARCHAR(32)` | `NOT NULL` — role **as held at the time** |
| `client_event_id` | `UUID` | `NOT NULL`, **globally unique** — idempotency key |
| `corrects_event_id` | `UUID` | → `boarding_events`. Set on compensating records. |
| `is_override` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `override_reason` | `TEXT` | Required when `is_override` |
| `latitude`, `longitude` | `NUMERIC(9,6)` | Device position at recording |
| `occurred_at` | `TIMESTAMPTZ` | `NOT NULL` — device clock |
| `recorded_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` — server receipt |
| `device_latitude` | `NUMERIC(9,6)` | Where the recording device was (BR-BOARD-002). Null when the handset had no fix — a boarding event without a position still counts (V23) |
| `device_longitude` | `NUMERIC(9,6)` | Given with the latitude or not at all (`ck_boarding_position_complete`) |
| `clock_skew_seconds` | `INTEGER` | Measured at sync |
| `sync_state` | `VARCHAR(16)` | `NOT NULL`, `SYNCED` / `FLAGGED_FOR_REVIEW` |

No soft-delete columns. No `updated_at`/`updated_by` — the row never changes.

```sql
CONSTRAINT uq_boarding_events_client_id UNIQUE (client_event_id),
CONSTRAINT ck_boarding_events_type      CHECK (event_type IN ('BOARD','ALIGHT')),
CONSTRAINT ck_boarding_events_override  CHECK (
    (is_override = false) OR (override_reason IS NOT NULL AND length(trim(override_reason)) > 0)),
CONSTRAINT ck_boarding_events_sync      CHECK (sync_state IN ('SYNCED','FLAGGED_FOR_REVIEW')),
CONSTRAINT fk_boarding_events_corrects  FOREIGN KEY (corrects_event_id)
    REFERENCES boarding_events(id) ON DELETE RESTRICT
```

### Why these choices

**`client_event_id` is globally unique, not per-tenant.** It is a client-generated UUID and is the sole mechanism making offline sync idempotent (BR-BOARD-009, ADR-0008). A retry after a timeout must not create a second boarding record for the same child.

**`ck_boarding_events_override` is a database constraint, not an application check.** BR-AUD-004 says an override without a reason is rejected; putting that in the schema means no code path — including a future one — can bypass it.

**`corrects_event_id` self-reference** implements BR-BOARD-001: a mis-scan produces two rows, both true. The original stays visible. There is no update path.

**Two timestamps** (ADR-0008): `occurred_at` for reporting, `recorded_at` for provenance, `clock_skew_seconds` for honesty about the device clock. Reports order by `occurred_at` (BR-BOARD-008).

**Indexes**
```sql
idx_boarding_events_trip     (tenant_id, trip_id, occurred_at)
idx_boarding_events_student  (tenant_id, student_id, occurred_at DESC)
uq_boarding_events_client_id (client_event_id)
idx_boarding_events_flagged  (tenant_id, sync_state) WHERE sync_state = 'FLAGGED_FOR_REVIEW'
```

**Rules:** BR-BOARD-001 (append-only + corrections), BR-BOARD-002 (all fields captured), BR-BOARD-008 (dual timestamps), BR-BOARD-009 (idempotency), BR-AUD-004 (override reason), BR-SAFE-005 (flagged, never discarded)

---

## `handovers`

Verified release of a student to an adult. Completes an `ALIGHT` event.

| Column | Type | Notes |
|---|---|---|
| `boarding_event_id` | `UUID` | `NOT NULL` **UNIQUE** → `boarding_events` |
| `received_by_guardian_id` | `UUID` | → `guardians` |
| `received_by_pickup_person_id` | `UUID` | → `authorised_pickup_persons` |
| `is_self_release` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `verification_method` | `VARCHAR(32)` | `NOT NULL`, `QR` / `OTP` / `PIN` / `VISUAL` / `OVERRIDE` |
| `is_override` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `override_reason` | `TEXT` | Required when `is_override` |
| `unverified_receiver_name` | `VARCHAR(255)` | Recorded identity of an unverified receiver |
| `unverified_receiver_phone` | `VARCHAR(32)` | |
| `actor_id` | `UUID` | `NOT NULL` — staff who performed the handover |
| `occurred_at` | `TIMESTAMPTZ` | `NOT NULL` |
| `recorded_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |

```sql
CONSTRAINT uq_handovers_boarding_event UNIQUE (boarding_event_id),
CONSTRAINT fk_handovers_boarding_event FOREIGN KEY (boarding_event_id)
    REFERENCES boarding_events(id) ON DELETE RESTRICT,

-- exactly one receiver path
CONSTRAINT ck_handovers_receiver CHECK (
    (received_by_guardian_id IS NOT NULL)::int
  + (received_by_pickup_person_id IS NOT NULL)::int
  + (is_self_release)::int
  + (is_override)::int = 1),

CONSTRAINT ck_handovers_override CHECK (
    (is_override = false) OR (
        override_reason IS NOT NULL AND length(trim(override_reason)) > 0
        AND unverified_receiver_name IS NOT NULL))
```

### Why these choices

**`boarding_event_id NOT NULL UNIQUE`** implements BR-HAND-004 structurally: a handover cannot exist without the alight record it completes, and an alight cannot be handed over twice.

**`ck_handovers_receiver`** is the important one. Exactly one of four mutually exclusive paths must hold — guardian, authorised pickup person, self-release, or override. Without this constraint a row could record a handover to nobody, or to two people, and BR-HAND-001 would be enforced only by application code.

**`ck_handovers_override`** requires that an override name the person the child was given to. An override recording "unverified adult" and nothing else is not evidence (BR-HAND-003).

**Indexes:** `idx_handovers_tenant_occurred (tenant_id, occurred_at DESC)`, `idx_handovers_overrides (tenant_id, occurred_at DESC) WHERE is_override`

**Rules:** BR-HAND-001 🔴, BR-HAND-003 🔴, BR-HAND-004, BR-HAND-005

**Not modelled here:** BR-HAND-006 (custody restriction) and BR-HAND-007 (no receiver present) are *refusals* — no handover row is created. They produce `incidents` and audit records instead. **A refused handover must leave a trace somewhere**, and that place is not this table.

---

## `reconciliations`

One per trip, created at `COMPLETED`. Gates closure (BR-SAFE-001 🔴).

| Column | Type | Notes |
|---|---|---|
| `trip_id` | `UUID` | `NOT NULL` **UNIQUE** → `trips` |
| `status` | `VARCHAR(24)` | `NOT NULL`, `PENDING` / `EXCEPTIONS` / `RESOLVED` |
| `expected_count`, `boarded_count`, `alighted_count` | `INTEGER` | `NOT NULL` |
| `started_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |
| `resolved_at` | `TIMESTAMPTZ` | |

```sql
CONSTRAINT uq_reconciliations_trip UNIQUE (tenant_id, trip_id),
CONSTRAINT ck_reconciliations_status CHECK (status IN ('PENDING','EXCEPTIONS','RESOLVED')),
CONSTRAINT ck_reconciliations_resolved CHECK (
    (status <> 'RESOLVED') OR (resolved_at IS NOT NULL))
```

---

## `reconciliation_items`

One per exception. **A trip cannot reach `CLOSED` while any item is unresolved** (BR-TRIP-009, BR-SAFE-001).

| Column | Type | Notes |
|---|---|---|
| `reconciliation_id` | `UUID` | `NOT NULL` → `reconciliations` |
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `exception_type` | `VARCHAR(32)` | `NOT NULL`, `UNACCOUNTED` / `NO_SHOW` / `WRONG_STOP` / `OFF_MANIFEST` |
| `resolution_outcome` | `VARCHAR(48)` | `FOUND_ON_VEHICLE` / `RECORD_MISSED` / `NEVER_BOARDED` / `CONFIRMED_NO_SHOW` |
| `resolution_notes` | `TEXT` | |
| `resolved_by` | `UUID` | → `users` |
| `resolved_at` | `TIMESTAMPTZ` | |

```sql
CONSTRAINT ck_reconciliation_items_type CHECK (
    exception_type IN ('UNACCOUNTED','NO_SHOW','WRONG_STOP','OFF_MANIFEST')),
CONSTRAINT ck_reconciliation_items_resolution CHECK (
    (resolution_outcome IS NULL AND resolved_by IS NULL AND resolved_at IS NULL)
 OR (resolution_outcome IS NOT NULL AND resolved_by IS NOT NULL AND resolved_at IS NOT NULL))
```

**`ck_reconciliation_items_resolution` is the safety invariant made structural:** a resolution is all-or-nothing. There is no way to record an outcome without recording **who** resolved it and **when**. `UNACCOUNTED` is the left-behind case — the one this entire platform exists to catch.

**Indexes:** `idx_reconciliation_items_unresolved (tenant_id, reconciliation_id) WHERE resolution_outcome IS NULL`

The partial index is the query that runs on every trip close.

**Rules:** BR-SAFE-001 🔴, BR-SAFE-002 🔴, BR-TRIP-009

---

## Append-Only Enforcement

Two independent controls, because the platform's evidentiary value rests on this property:

```sql
-- 1. Grants
REVOKE UPDATE, DELETE ON boarding_events, handovers FROM guardian_app;

-- 2. Trigger
CREATE OR REPLACE FUNCTION reject_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'Table % is append-only (BR-BOARD-001)', TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_boarding_events_append_only
    BEFORE UPDATE OR DELETE ON boarding_events
    FOR EACH ROW EXECUTE FUNCTION reject_mutation();
```

`reconciliation_items` permits a single controlled `UPDATE` to set the resolution fields — the only mutation allowed in this module, and it is one-way (guarded by the check constraint above, which prevents a partial resolution, and by a trigger rejecting any update once `resolved_at` is set).

---

## Verification

1. `UPDATE` or `DELETE` on `boarding_events` or `handovers` raises an exception.
2. Duplicate `client_event_id` insert is rejected — offline replay is idempotent.
3. An override without a reason is rejected by constraint, not just by the application.
4. A handover with zero or two receiver paths is rejected.
5. A handover without a `boarding_event_id` cannot be inserted.
6. A reconciliation item cannot record an outcome without actor and time.
7. A trip with an unresolved reconciliation item cannot transition to `CLOSED`.
8. A correction record references its original and both remain readable.
