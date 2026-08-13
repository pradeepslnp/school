# MOD-07 — Routes & Stops Tables

**Owning module:** `com.guardian.route` · **Rules:** BR-ROUTE-*

These tables define what *should* happen. [`MOD-08-trips.md`](MOD-08-trips.md) records what *did*.

---

## `routes`

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` |
| `code` | `VARCHAR(32)` | `NOT NULL`, unique within school |
| `name` | `VARCHAR(255)` | `NOT NULL` |
| `default_vehicle_id` | `UUID` | → `vehicles` |
| `corridor_width_m` | `INTEGER` | Deviation threshold (BR-ALERT-002); null = tenant default |
| `path_geometry` | `JSONB` | Encoded polyline for corridor calculation and map display |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT uq_routes_school_code UNIQUE (tenant_id, school_id, code)
```

`path_geometry` is `JSONB` — one of the few permitted uses ([`CONVENTIONS.md`](../CONVENTIONS.md)). It is read as a whole for map rendering and corridor computation, never queried by its internal structure, and no business rule depends on a field inside it.

`corridor_width_m` is nullable so a route inherits the tenant default unless it needs its own — a narrow lane and a highway stretch warrant different tolerances.

**Rules:** BR-ROUTE-001, BR-ROUTE-007 (deactivation requires reassigning every student)

---

## `stops`

| Column | Type | Notes |
|---|---|---|
| `route_id` | `UUID` | `NOT NULL` → `routes` |
| `sequence_no` | `INTEGER` | `NOT NULL`, `> 0` |
| `name` | `VARCHAR(255)` | `NOT NULL` — appears in notifications |
| `latitude`, `longitude` | `NUMERIC(9,6)` | `NOT NULL` |
| `geofence_radius_m` | `INTEGER` | `NOT NULL` |
| `scheduled_pickup_time` | `TIME` | School time zone |
| `scheduled_drop_time` | `TIME` | |
| `landmark` | `VARCHAR(255)` | Helps parents locate the stop |

```sql
CONSTRAINT uq_stops_route_sequence UNIQUE (tenant_id, route_id, sequence_no),
CONSTRAINT ck_stops_sequence  CHECK (sequence_no > 0),
CONSTRAINT ck_stops_latitude  CHECK (latitude  BETWEEN -90  AND 90),
CONSTRAINT ck_stops_longitude CHECK (longitude BETWEEN -180 AND 180),
CONSTRAINT ck_stops_geofence  CHECK (geofence_radius_m BETWEEN 20 AND 500)
```

### Geofence radius bounds

`ck_stops_geofence` implements BR-ROUTE-003 and BR-CFG-003 🔴 in the schema. The bounds are not arbitrary:

- **Too small** (< 20 m) and GPS drift means arrival is never detected — parents get no approach notification and the stop appears skipped.
- **Too large** (> 500 m) and geofences overlap, so the vehicle registers as arriving at several stops simultaneously and arrival events become meaningless.

A tenant may tune within this window (ADR-0007); they cannot leave it (BR-SAFE-007). Placing the floor and ceiling in the database means no configuration path, present or future, can violate them.

**Times are `TIME`, not `TIMESTAMPTZ`** — a stop is scheduled for "07:40 local", every operating day. The date comes from the trip; the zone from the school (BR-CFG-006).

**BR-ROUTE-008** (strictly increasing times along the sequence) is a cross-row invariant PostgreSQL cannot express as a check constraint. It is enforced in the domain on route save and covered by a test — **a documented deviation** from enforce-structurally.

**Indexes:** `uq_stops_route_sequence` serves ordered retrieval directly.

---

## `route_student_assignments`

Which student boards where, in which direction.

| Column | Type | Notes |
|---|---|---|
| `route_id` | `UUID` | `NOT NULL` → `routes` |
| `stop_id` | `UUID` | `NOT NULL` → `stops` |
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `direction` | `VARCHAR(16)` | `NOT NULL`, `PICKUP` / `DROP` |
| `effective_from`, `effective_until` | `DATE` | |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT ck_rsa_direction CHECK (direction IN ('PICKUP','DROP')),
CONSTRAINT uq_rsa_student_direction
    UNIQUE (tenant_id, student_id, direction) WHERE is_active
```

### The unique constraint is the important part

`uq_rsa_student_direction` enforces BR-ROUTE-004 structurally: **a student has at most one active pickup assignment and at most one active drop assignment.** Two active pickup assignments would put one child on two manifests, and the wrong-vehicle control (BR-SAFE-003) would fire on a legitimate boarding — or worse, fail to fire on an illegitimate one.

Note the constraint is on `(student_id, direction)` and deliberately **not** on `route_id` — a student may use different routes for pickup and drop (BR-ROUTE-005), which is common where parents drop off but the bus returns.

**Indexes:** `idx_rsa_route_direction (tenant_id, route_id, direction) WHERE is_active` — this is the query that materialises a manifest at trip start (BR-TRIP-003), so it runs for every trip.

**Rules:** BR-ROUTE-004, BR-ROUTE-005, BR-STU-002 (assignment requires an active guardian), BR-STU-004 (active enrolment only)

---

## Change Semantics

**Editing a route does not alter trips already started** (BR-ROUTE-006). The manifest is materialised at trip start and immutable thereafter (BR-TRIP-003), so route edits apply only to trips generated afterwards.

This is why `trip_manifests` exists as its own table rather than being derived from these assignments on read. A trip that ran three months ago must show who was expected *that day* — see [`DATA_MODEL_OVERVIEW.md`](../DATA_MODEL_OVERVIEW.md).

**Deactivating a route** requires every assigned student to be reassigned or explicitly released first (BR-ROUTE-007). Enforced in the application; a route with active assignments cannot be deactivated.

---

## Verification

1. A stop with a geofence radius outside 20–500 m is rejected by the database.
2. A second active pickup assignment for the same student is rejected by constraint.
3. A student may hold pickup on route A and drop on route B.
4. Stop times not strictly increasing along the sequence are rejected on save.
5. Editing a route does not change an in-progress trip's manifest.
6. A route with active student assignments cannot be deactivated.
7. Assigning a student with no active guardian is refused (BR-STU-002).
