# MOD-05 / MOD-06 — Fleet & Staff Tables

**Owning modules:** `com.guardian.fleet`, `com.guardian.staff` · **Rules:** BR-FLEET-*, BR-STAFF-*

Both modules exist to answer one question at trip start: **is this vehicle and this crew permitted to carry children today?**

---

## `vehicles`

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` |
| `registration_no` | `VARCHAR(32)` | `NOT NULL`, unique within organization |
| `display_name` | `VARCHAR(64)` | `NOT NULL` — "Bus 12"; what parents see |
| `vehicle_type` | `VARCHAR(24)` | `NOT NULL`, `BUS` / `VAN` / `MINIBUS` |
| `seating_capacity` | `INTEGER` | `NOT NULL`, `> 0` |
| `vendor_name` | `VARCHAR(255)` | Set for outsourced fleets |
| `status` | `VARCHAR(24)` | `NOT NULL`, `ACTIVE` / `MAINTENANCE` / `RETIRED` |

```sql
CONSTRAINT uq_vehicles_registration UNIQUE (tenant_id, registration_no),
CONSTRAINT ck_vehicles_capacity     CHECK (seating_capacity > 0),
CONSTRAINT ck_vehicles_status       CHECK (status IN ('ACTIVE','MAINTENANCE','RETIRED'))
```

`display_name` is separate from `registration_no` because notifications say "Bus 12", not a plate number (NTF-BOARD-01).

**Indexes:** `idx_vehicles_tenant_school (tenant_id, school_id) WHERE status = 'ACTIVE'`

**Rules:** BR-FLEET-001, BR-FLEET-005

---

## `vehicle_documents` 🔴

Compliance artefacts. Expiry **blocks trip assignment** (BR-FLEET-002).

| Column | Type | Notes |
|---|---|---|
| `vehicle_id` | `UUID` | `NOT NULL` → `vehicles` |
| `document_type` | `VARCHAR(48)` | `NOT NULL` — value from the region profile, **not a code enum** |
| `document_number` | `VARCHAR(128)` | |
| `issued_on` | `DATE` | |
| `expires_on` | `DATE` | `NOT NULL` |
| `is_mandatory` | `BOOLEAN` | `NOT NULL` — from the region profile |
| `file_ref` | `VARCHAR(255)` | Scanned copy; served through an authorising endpoint |

```sql
CONSTRAINT ck_vehicle_documents_dates CHECK (issued_on IS NULL OR expires_on > issued_on)
```

**`document_type` is free-form against region reference data, not a database enum** (ADR-0007). Registration, fitness, insurance, and permit types differ by country. A code enum here would mean a code change to onboard a new market — the exact failure ADR-0007 forbids.

**What is *not* configurable:** that a mandatory expired document blocks assignment. Tenants configure *which* documents are mandatory; they cannot configure the block away (BR-FLEET-002 🔴).

**Indexes:** `idx_vehicle_documents_expiry (tenant_id, expires_on) WHERE is_mandatory`

Serves both the daily expiry-warning job (BR-FLEET-003) and the trip-start eligibility check.

---

## `devices`

| Column | Type | Notes |
|---|---|---|
| `vehicle_id` | `UUID` | → `vehicles`. Null when unassigned. |
| `device_identifier` | `VARCHAR(128)` | `NOT NULL` **globally unique** |
| `vendor_code` | `VARCHAR(48)` | `NOT NULL` — selects the adapter (ADR-0004) |
| `credential_hash` | `VARCHAR(255)` | `NOT NULL` — device authentication |
| `last_seen_at` | `TIMESTAMPTZ` | Drives signal-loss detection (BR-TRACK-005) |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT uq_devices_identifier UNIQUE (device_identifier),
CONSTRAINT uq_devices_vehicle_active UNIQUE (tenant_id, vehicle_id) WHERE is_active
```

**`uq_devices_vehicle_active` enforces BR-FLEET-004 structurally** — at most one active device per vehicle. Two devices reporting for one bus would produce contradictory positions.

`device_identifier` is globally unique because ingestion resolves the device *before* it knows the tenant ([`REALTIME_TRACKING_DESIGN.md`](../../02-system-design/REALTIME_TRACKING_DESIGN.md)). An unknown device is logged and ignored, **never auto-registered** (BR-FLEET-006) — auto-registration would let anyone inject positions for a vehicle they do not own.

---

## `transport_staff`

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` |
| `user_id` | `UUID` | → `users`. Null until the account is activated. |
| `staff_type` | `VARCHAR(24)` | `NOT NULL`, `DRIVER` / `ATTENDANT` |
| `employee_code` | `VARCHAR(64)` | Unique within school where present |
| `first_name`, `last_name` | `VARCHAR(128)` | `NOT NULL` |
| `phone` | `VARCHAR(32)` | `NOT NULL` |
| `photo_ref` | `VARCHAR(255)` | |
| `vendor_name` | `VARCHAR(255)` | Set for outsourced staff |
| `verification_status` | `VARCHAR(24)` | `NOT NULL`, `PENDING` / `VERIFIED` / `LAPSED` / `REJECTED` |
| `verified_until` | `DATE` | |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT ck_staff_type   CHECK (staff_type IN ('DRIVER','ATTENDANT')),
CONSTRAINT ck_staff_verify CHECK (
    verification_status IN ('PENDING','VERIFIED','LAPSED','REJECTED')),
CONSTRAINT ck_staff_verified_until CHECK (
    verification_status <> 'VERIFIED' OR verified_until IS NOT NULL)
```

**`ck_staff_verified_until`** prevents a permanently-verified staff member. Background verification expires; a record claiming `VERIFIED` with no end date is a verification nobody will ever revisit (BR-STAFF-002 🔴).

**Indexes:** `idx_staff_tenant_school (tenant_id, school_id) WHERE is_active`, `idx_staff_verification (tenant_id, verified_until) WHERE verification_status = 'VERIFIED'`

---

## `staff_credentials` 🔴

| Column | Type | Notes |
|---|---|---|
| `staff_id` | `UUID` | `NOT NULL` → `transport_staff` |
| `credential_type` | `VARCHAR(48)` | `NOT NULL` — from region profile |
| `credential_number` | `VARCHAR(128)` | |
| `credential_class` | `VARCHAR(32)` | Licence class — checked against vehicle type (BR-STAFF-001) |
| `issued_on` | `DATE` | |
| `expires_on` | `DATE` | `NOT NULL` |
| `is_mandatory` | `BOOLEAN` | `NOT NULL` |
| `file_ref` | `VARCHAR(255)` | |

**Indexes:** `idx_staff_credentials_expiry (tenant_id, expires_on) WHERE is_mandatory`

**Rules:** BR-STAFF-001 🔴 (valid licence of required class), BR-STAFF-003 (warnings then blocking)

Like vehicle documents, `credential_type` and `credential_class` come from region reference data (ADR-0007).

---

## `duty_assignments`

Which staff normally crew which route.

| Column | Type | Notes |
|---|---|---|
| `staff_id` | `UUID` | `NOT NULL` → `transport_staff` |
| `route_id` | `UUID` | `NOT NULL` → `routes` |
| `role` | `VARCHAR(24)` | `NOT NULL`, `DRIVER` / `ATTENDANT` |
| `direction` | `VARCHAR(16)` | `PICKUP` / `DROP` / null = both |
| `effective_from`, `effective_until` | `DATE` | |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

This is the *default* crew. Actual crew for a specific trip lives in `trip_staff` ([`MOD-08-trips.md`](MOD-08-trips.md)) — separated so a substitution (BR-STAFF-006) does not rewrite the standing roster.

**Rules:** BR-STAFF-004 (one active trip per staff member — enforced at trip start against `trip_staff`)

---

## Trip-Start Eligibility

These tables converge into one check (BR-TRIP-004). All must pass:

```
Vehicle ACTIVE
  ∧ no mandatory vehicle_document with expires_on < today        BR-FLEET-002 🔴
  ∧ driver verification_status = VERIFIED ∧ verified_until ≥ today   BR-STAFF-002 🔴
  ∧ driver holds unexpired credential of required class          BR-STAFF-001 🔴
  ∧ attendant present if tenant configuration requires one       BR-STAFF-005
  ∧ neither vehicle nor driver on another active trip            BR-TRIP-005, BR-STAFF-004
```

Failure refuses trip start with a specific reason — never a generic error. A driver told only "cannot start" at 6:30 AM cannot fix the problem.

An **in-progress** trip is never interrupted by an expiry occurring mid-journey (BR-FLEET-002 note, J8).

---

## Verification

1. A vehicle with an expired mandatory document cannot be assigned to a trip.
2. A driver with an expired licence cannot be assigned.
3. A driver whose verification has lapsed cannot be assigned.
4. Two active devices cannot exist for one vehicle.
5. An unknown device's position report is logged and ignored, not auto-registered.
6. A `VERIFIED` staff record cannot be saved without `verified_until`.
7. Trip-start refusal names the specific failing check.
8. A document expiring mid-trip does not stop the in-progress trip.
