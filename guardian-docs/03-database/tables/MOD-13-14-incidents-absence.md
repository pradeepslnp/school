# MOD-13 / MOD-14 — Incidents & Absence Tables

**Owning modules:** `com.guardian.incident`, `com.guardian.absence` · **Rules:** BR-INC-*, BR-ABS-*

`sos_alerts` and `incidents` are **append-only for creation** — they are resolved, never deleted (BR-INC-002, BR-INC-006).

---

## `sos_alerts` 🔴

The highest-priority event class in the platform.

| Column | Type | Notes |
|---|---|---|
| `trip_id` | `UUID` | → `trips` |
| `vehicle_id` | `UUID` | → `vehicles` |
| `raised_by_user_id` | `UUID` | `NOT NULL` → `users` |
| `raised_by_role` | `VARCHAR(24)` | `NOT NULL` — role **as held at the time** |
| `source` | `VARCHAR(24)` | `NOT NULL`, `DRIVER_APP` / `ATTENDANT_APP` / `DEVICE_BUTTON` |
| `latitude`, `longitude` | `NUMERIC(9,6)` | Position at the moment of raising |
| `status` | `VARCHAR(24)` | `NOT NULL`, `RAISED` / `ACKNOWLEDGED` / `RESOLVED` |
| `raised_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |
| `acknowledged_at`, `acknowledged_by` | | |
| `resolved_at`, `resolved_by` | | |
| `resolution_outcome` | `VARCHAR(48)` | `GENUINE_EMERGENCY` / `FALSE_ALARM` / `ACCIDENTAL` / `RESOLVED_ON_SITE` |
| `resolution_notes` | `TEXT` | |

```sql
CONSTRAINT ck_sos_status CHECK (status IN ('RAISED','ACKNOWLEDGED','RESOLVED')),
CONSTRAINT ck_sos_acknowledged CHECK (
    status = 'RAISED' OR (acknowledged_at IS NOT NULL AND acknowledged_by IS NOT NULL)),
CONSTRAINT ck_sos_resolved CHECK (
    status <> 'RESOLVED' OR (resolved_at IS NOT NULL AND resolved_by IS NOT NULL
                             AND resolution_outcome IS NOT NULL))
```

### An SOS is never deleted

`FALSE_ALARM` is a *resolution outcome*, not a delete (BR-INC-006). This matters: a driver whose SOS button is accidentally pressed weekly is a pattern worth seeing — a faulty device, or a button placed where it catches a sleeve. Deleting false alarms would erase exactly the data that reveals the problem.

`ck_sos_resolved` makes closure require an actor, a time, and an outcome — all three, or none.

`raised_by_role` is snapshotted because roles change; the record must show the role held when the alert was raised.

**Indexes:** `idx_sos_open (tenant_id, status, raised_at DESC) WHERE status <> 'RESOLVED'`

**Rules:** BR-INC-001 🔴, BR-INC-002, BR-INC-006, BR-SAFE-004 🔴

---

## `incidents`

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` |
| `trip_id` | `UUID` | → `trips` |
| `student_id` | `UUID` | → `students`. Set when a specific child is affected. |
| `vehicle_id` | `UUID` | → `vehicles` |
| `incident_type` | `VARCHAR(48)` | `NOT NULL`, `ACCIDENT` / `BREAKDOWN` / `MEDICAL` / `BEHAVIOURAL` / `HANDOVER_REFUSED` / `NO_RECEIVER` / `OTHER` |
| `severity` | `VARCHAR(16)` | `NOT NULL`, `LOW` / `MEDIUM` / `HIGH` / `CRITICAL` |
| `status` | `VARCHAR(16)` | `NOT NULL`, `OPEN` / `IN_PROGRESS` / `RESOLVED` |
| `description` | `TEXT` | `NOT NULL` |
| `reported_by_user_id` | `UUID` | `NOT NULL` → `users` |
| `occurred_at` | `TIMESTAMPTZ` | `NOT NULL` |
| `resolved_at`, `resolved_by` | | |
| `resolution_outcome` | `VARCHAR(64)` | |

```sql
CONSTRAINT ck_incidents_severity CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
CONSTRAINT ck_incidents_status   CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED')),
CONSTRAINT ck_incidents_resolved CHECK (
    status <> 'RESOLVED' OR (resolved_at IS NOT NULL AND resolved_by IS NOT NULL
                             AND resolution_outcome IS NOT NULL))
```

### `HANDOVER_REFUSED` and `NO_RECEIVER`

These two types carry the traces of the handover refusals that create **no** `handovers` row ([`MOD-09-boarding.md`](MOD-09-boarding.md)):

- **`HANDOVER_REFUSED`** — a custody-restricted person attempted collection (BR-HAND-006 🔴).
- **`NO_RECEIVER`** — nobody was present; the child stayed on the vehicle (BR-HAND-007 🔴).

A refused handover must leave a record somewhere. Because the handover did not happen, that place is here.

**Notification audience follows severity** (BR-INC-004): a `student_id`-scoped incident notifies that child's guardians; a trip-scoped incident notifies all guardians on the manifest **without naming any child** (BR-NTF-007 🔴).

**Indexes:** `idx_incidents_open (tenant_id, school_id, severity, occurred_at DESC) WHERE status <> 'RESOLVED'`, `idx_incidents_student (tenant_id, student_id, occurred_at DESC)`

---

## `incident_escalations`

The escalation trail (BR-SAFE-006 🔴). Append-only.

| Column | Type | Notes |
|---|---|---|
| `incident_id` | `UUID` | → `incidents` |
| `sos_alert_id` | `UUID` | → `sos_alerts` |
| `level` | `INTEGER` | `NOT NULL`, `>= 1` |
| `notified_role` | `VARCHAR(32)` | `NOT NULL` |
| `notified_user_id` | `UUID` | → `users` |
| `notified_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |
| `acknowledged_at` | `TIMESTAMPTZ` | |

```sql
CONSTRAINT ck_escalations_subject CHECK (
    (incident_id IS NOT NULL)::int + (sos_alert_id IS NOT NULL)::int = 1),
CONSTRAINT ck_escalations_level CHECK (level >= 1)
```

Each row is one notification attempt at one level. Unacknowledged, the escalation job inserts the next level and repeats **until acknowledged** (BR-SAFE-006). The full chain remains visible afterwards — who was told, when, and who finally responded.

**Indexes:** `idx_escalations_unack (tenant_id, notified_at) WHERE acknowledged_at IS NULL` — drives the escalation job.

---

## `absence_declarations`

| Column | Type | Notes |
|---|---|---|
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `declared_by_guardian_id` | `UUID` | → `guardians`. Null when declared by staff. |
| `declared_by_user_id` | `UUID` | `NOT NULL` → `users` |
| `absence_date` | `DATE` | `NOT NULL` |
| `direction` | `VARCHAR(16)` | `PICKUP` / `DROP` / null = both |
| `reason` | `VARCHAR(255)` | Optional — parents are not required to explain |
| `is_cancelled` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `cancelled_at`, `cancelled_by` | | |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |

```sql
CONSTRAINT uq_absence UNIQUE (tenant_id, student_id, absence_date, direction),
CONSTRAINT ck_absence_direction CHECK (direction IS NULL OR direction IN ('PICKUP','DROP'))
```

**`reason` is deliberately optional.** Requiring a parent to justify their child's absence is friction with no safety value — the platform needs to know the child is not travelling, not why.

Cancellation is a flag, not a delete (BR-ABS-004) — a declaration made and withdrawn is part of the record when a no-show is later questioned.

**Interaction with the manifest:**

| Timing | Effect |
|---|---|
| Before trip start | Student excluded from materialisation (BR-ABS-002); no-show alerts suppressed (BR-ABS-005) |
| After trip start | Manifest is immutable (BR-TRIP-003) — recorded as an amendment instead (BR-ABS-003) |
| Student boards despite absence | Alert raised, absence removed, **both facts recorded** (BR-BOARD-007) |

**Indexes:** `idx_absence_lookup (tenant_id, absence_date, student_id) WHERE NOT is_cancelled` — read at every trip materialisation.

---

## Verification

1. An SOS cannot be deleted; `FALSE_ALARM` is recorded as an outcome.
2. Resolving an SOS or incident without actor, time, and outcome is rejected.
3. An unacknowledged escalation advances a level and inserts a new row.
4. A custody-restricted collection attempt creates a `HANDOVER_REFUSED` incident and no handover row.
5. A no-receiver event creates a `NO_RECEIVER` incident and the child remains on the manifest as boarded.
6. A trip-scoped incident notification names no student.
7. An absence before trip start excludes the student from the manifest.
8. An absence after trip start creates an amendment and leaves the manifest unchanged.
9. A student boarding despite a declared absence raises an alert and records both facts.
