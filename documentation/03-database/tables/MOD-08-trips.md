# MOD-08 — Trip Execution Tables

**Owning module:** `com.guardian.trip` · **Rules:** BR-TRIP-*

The operational centre. **Every safety event is anchored to a trip.**

---

## `trips`

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` — denormalised from route for query efficiency |
| `route_id` | `UUID` | `NOT NULL` → `routes` |
| `vehicle_id` | `UUID` | → `vehicles`. Null until started. |
| `service_date` | `DATE` | `NOT NULL` |
| `direction` | `VARCHAR(16)` | `NOT NULL`, `PICKUP` / `DROP` |
| `status` | `VARCHAR(24)` | `NOT NULL` |
| `scheduled_start_time` | `TIME` | School time zone |
| `started_at`, `completed_at`, `closed_at` | `TIMESTAMPTZ` | Server-recorded (BR-TRIP-008) |
| `device_started_at` | `TIMESTAMPTZ` | Device-reported, for reference only |
| `cancelled_at`, `cancellation_reason` | | |

```sql
CONSTRAINT uq_trips_route_date_direction
    UNIQUE (tenant_id, route_id, service_date, direction),
CONSTRAINT ck_trips_status CHECK (status IN (
    'SCHEDULED','STARTED','IN_PROGRESS','COMPLETED','CLOSED','CANCELLED')),
CONSTRAINT ck_trips_started   CHECK (status = 'SCHEDULED' OR started_at IS NOT NULL),
CONSTRAINT ck_trips_vehicle   CHECK (status IN ('SCHEDULED','CANCELLED') OR vehicle_id IS NOT NULL),
CONSTRAINT ck_trips_completed CHECK (status NOT IN ('COMPLETED','CLOSED') OR completed_at IS NOT NULL),
CONSTRAINT ck_trips_closed    CHECK (status <> 'CLOSED' OR closed_at IS NOT NULL),
CONSTRAINT ck_trips_cancelled CHECK (status <> 'CANCELLED' OR
    (cancelled_at IS NOT NULL AND cancellation_reason IS NOT NULL))
```

### Why `school_id` is denormalised

It is reachable via `route_id → routes.school_id`, but the hottest query in the platform — *active trips for a school* — runs constantly during peak windows ([`INDEXING_AND_PARTITIONING.md`](../INDEXING_AND_PARTITIONING.md)). Carrying `school_id` here avoids a join on that path. A route cannot move between schools, so the denormalisation cannot go stale.

### Status is a `VARCHAR` + `CHECK`, not a native enum

Per [`CONVENTIONS.md`](../CONVENTIONS.md): altering a PostgreSQL enum requires migration gymnastics, and this list will grow.

The transition graph (BR-TRIP-002) is enforced in the domain, not the schema — SQL cannot express "from `STARTED` you may reach `IN_PROGRESS` or `CANCELLED` but not `CLOSED`". The check constraints above enforce what SQL *can*: that each status carries its required timestamps. **A documented deviation**, covered by a state-machine test.

`ck_trips_cancelled` makes BR-TRIP-007 structural — a cancellation always carries a reason, because the guardian notification quotes it.

**Indexes**
```sql
uq_trips_route_date_direction
idx_trips_active (tenant_id, school_id, status) WHERE status IN ('STARTED','IN_PROGRESS')
idx_trips_service_date (tenant_id, school_id, service_date)
idx_trips_vehicle_active (tenant_id, vehicle_id) WHERE status IN ('STARTED','IN_PROGRESS')
```

`idx_trips_vehicle_active` serves BR-TRIP-005 — the check that a vehicle is not already on another active trip.

**Rules:** BR-TRIP-001, BR-TRIP-002, BR-TRIP-005, BR-TRIP-007, BR-TRIP-008, BR-TRIP-011

---

## `trip_manifests` 🔴

**Materialised at trip start; immutable thereafter** (BR-TRIP-003).

| Column | Type | Notes |
|---|---|---|
| `trip_id` | `UUID` | `NOT NULL` → `trips` |
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `expected_stop_id` | `UUID` | `NOT NULL` → `stops` |
| `student_name_snapshot` | `VARCHAR(255)` | `NOT NULL` — name as at materialisation |
| `sequence_no` | `INTEGER` | `NOT NULL` — stop order, denormalised |
| `status` | `VARCHAR(24)` | `NOT NULL`, `EXPECTED` / `BOARDED` / `ALIGHTED` / `NO_SHOW` / `ABSENT` |

```sql
CONSTRAINT uq_trip_manifests UNIQUE (tenant_id, trip_id, student_id),
CONSTRAINT ck_trip_manifests_status CHECK (
    status IN ('EXPECTED','BOARDED','ALIGHTED','NO_SHOW','ABSENT'))
```

### Why materialise rather than derive

Route assignments change. Students move stops, leave the school, get reassigned. A trip that ran three months ago must show **who was expected on it that day** — deriving from current assignments would silently rewrite history.

In a system whose records are evidence after an incident, a manifest that changes retroactively is worse than useless.

`student_name_snapshot` follows the same reasoning: a name correction later should not alter what a printed manifest showed the attendant that morning.

**`status` is the one mutable field** — it advances as boarding events arrive. The membership of the manifest never changes; only each row's progress does. Changes to membership go to `trip_manifest_amendments`.

**Indexes:** `idx_trip_manifests_trip (tenant_id, trip_id)`, `idx_trip_manifests_student (tenant_id, student_id)`

---

## `trip_manifest_amendments`

Append-only record of post-start manifest changes (BR-TRIP-003, BR-ABS-003).

| Column | Type | Notes |
|---|---|---|
| `trip_id` | `UUID` | `NOT NULL` → `trips` |
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `amendment_type` | `VARCHAR(24)` | `NOT NULL`, `ADDED` / `REMOVED` / `STOP_CHANGED` |
| `previous_stop_id`, `new_stop_id` | `UUID` | → `stops` |
| `reason` | `TEXT` | `NOT NULL` |
| `actor_id` | `UUID` | `NOT NULL` |
| `occurred_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |

```sql
CONSTRAINT ck_amendments_type CHECK (amendment_type IN ('ADDED','REMOVED','STOP_CHANGED')),
CONSTRAINT ck_amendments_reason CHECK (length(trim(reason)) > 0)
```

**`reason` is `NOT NULL` and non-empty.** A late absence declared after departure, or a child added at the gate, is exactly the kind of change that gets questioned afterwards. An unexplained amendment is not evidence (BR-AUD-004).

---

## `trip_staff`

Actual crew for this trip — distinct from the standing roster in `duty_assignments`.

| Column | Type | Notes |
|---|---|---|
| `trip_id` | `UUID` | `NOT NULL` → `trips` |
| `staff_id` | `UUID` | `NOT NULL` → `transport_staff` |
| `role` | `VARCHAR(24)` | `NOT NULL`, `DRIVER` / `ATTENDANT` |
| `assigned_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |
| `unassigned_at` | `TIMESTAMPTZ` | Set on mid-trip substitution |
| `replaced_staff_id` | `UUID` | → `transport_staff` (BR-STAFF-006) |

```sql
CONSTRAINT ck_trip_staff_role CHECK (role IN ('DRIVER','ATTENDANT')),
CONSTRAINT uq_trip_staff_active
    UNIQUE (tenant_id, trip_id, role) WHERE unassigned_at IS NULL
```

`uq_trip_staff_active` guarantees one active driver and one active attendant per trip at any moment — a substitution must unassign before assigning.

**Substitutions append rather than overwrite** (BR-STAFF-006): the outgoing row gets `unassigned_at`, the incoming row references it via `replaced_staff_id`. Both remain. After an incident, "who was driving at 3:15 PM" must be answerable.

**Indexes:** `idx_trip_staff_staff_active (tenant_id, staff_id) WHERE unassigned_at IS NULL` — serves BR-STAFF-004 (one active trip per staff member).

---

## Lifecycle

```
SCHEDULED ──start──► STARTED ──first boarding──► IN_PROGRESS
    │                   │                             │
    │                   │                             ▼
    └───────────────────┴──cancel──► CANCELLED    COMPLETED
                                                       │
                                          reconciliation gate 🔴
                                          BR-TRIP-009 / BR-SAFE-001
                                                       ▼
                                                    CLOSED
```

**The reconciliation gate is the platform's most important invariant.** A trip cannot reach `CLOSED` while any `reconciliation_items` row is unresolved ([`MOD-09-boarding.md`](MOD-09-boarding.md)) — which means a trip with an unaccounted child stays visibly open until a human resolves it with an explicit outcome.

At `STARTED`, materialisation runs (BR-TRIP-003):

```
route_student_assignments (active, this route + direction)
   MINUS absence_declarations (this date + direction, not cancelled)
   WHERE student enrolment_status = ACTIVE
        ▼
   trip_manifests rows, status = EXPECTED
```

---

## Verification

1. Two trips for the same route, date, and direction cannot be created.
2. A trip cannot start when its vehicle or driver is on another active trip.
3. A `CANCELLED` trip without a reason is rejected by constraint.
4. Route edits after trip start do not change the materialised manifest.
5. A manifest amendment without a reason is rejected.
6. A trip with an unresolved reconciliation item cannot reach `CLOSED`.
7. A mid-trip substitution leaves both crew rows, linked, with times.
8. Invalid status transitions are rejected by the domain state machine.
