# INDEXING AND PARTITIONING

**Document tier:** 3 — Database
**Status:** Active

---

## The Governing Rule

**Every tenant-scoped index leads with `tenant_id`.**

The RLS predicate `tenant_id = current_setting('app.tenant_id')` applies to *every* query against *every* tenant-scoped table ([`RLS_POLICIES.md`](RLS_POLICIES.md)). An index not leading with `tenant_id` cannot serve that predicate efficiently, so the planner falls back to a scan filtered by RLS.

```sql
-- correct
CREATE INDEX idx_students_tenant_school ON students (tenant_id, school_id);

-- wrong: cannot serve the RLS predicate
CREATE INDEX idx_students_school ON students (school_id);
```

An index review is part of the definition of done for any query added to a hot path.

---

## Indexes by Access Pattern

Ordered by how often they run, not by table.

### Very high frequency (peak windows)

| Query | Index |
|---|---|
| Guardian's children's trips today | `route_student_assignments (tenant_id, student_id, direction) WHERE is_active` |
| Active trips for a school | `trips (tenant_id, school_id, status) WHERE status IN ('STARTED','IN_PROGRESS')` |
| Trip manifest | `trip_manifests (tenant_id, trip_id)` |
| Guardian → students | `guardian_student_links (tenant_id, guardian_id) WHERE is_active` |
| Student → guardians | `guardian_student_links (tenant_id, student_id) WHERE is_active` |

Live position is served from Redis and needs no index (ADR-0004).

### High frequency

| Query | Index |
|---|---|
| Boarding events for a trip | `boarding_events (tenant_id, trip_id, occurred_at)` |
| Student's boarding history | `boarding_events (tenant_id, student_id, occurred_at DESC)` |
| Idempotency check on sync | `boarding_events (client_event_id)` **UNIQUE** |
| Open alerts for a school | `alerts (tenant_id, school_id, status) WHERE status = 'OPEN'` |
| Pending notification deliveries | `notification_deliveries (tenant_id, status) WHERE status = 'PENDING'` |
| Session lookup by refresh token | `sessions (refresh_token_hash)` **UNIQUE** |

`boarding_events (client_event_id)` is unique **globally, not per tenant** — it is a client-generated UUID and uniqueness is what makes offline sync idempotent (BR-BOARD-009, ADR-0008).

### Moderate frequency

| Query | Index |
|---|---|
| Trip by route and date | `trips (tenant_id, route_id, service_date, direction)` **UNIQUE** |
| Stops in route order | `stops (tenant_id, route_id, sequence_no)` **UNIQUE** |
| Students by school | `students (tenant_id, school_id) WHERE enrolment_status = 'ACTIVE'` |
| Admission number lookup | `students (tenant_id, school_id, admission_no)` **UNIQUE** |
| Absences for a date | `absence_declarations (tenant_id, absence_date, student_id) WHERE NOT is_cancelled` |
| Expiring vehicle documents | `vehicle_documents (tenant_id, expires_on) WHERE is_mandatory` |
| Expiring staff credentials | `staff_credentials (tenant_id, expires_on)` |
| Unresolved reconciliation items | `reconciliation_items (tenant_id, reconciliation_id) WHERE resolution_outcome IS NULL` |

### Audit and reporting

| Query | Index |
|---|---|
| Audit by subject | `audit_records (tenant_id, subject_type, subject_id, occurred_at DESC)` |
| Audit by actor | `audit_records (tenant_id, actor_id, occurred_at DESC)` |
| Audit by correlation | `audit_records (correlation_id)` |
| Overrides register | `audit_records (tenant_id, action, occurred_at DESC) WHERE reason IS NOT NULL` |
| Child data access | `data_access_records (tenant_id, student_id, occurred_at DESC)` |

Reporting runs against a read replica (BR-RPT-004), so these indexes cost write throughput on the primary without serving it — they are kept deliberately few.

---

## Search (trigram)

Global search (SRC-001) matches substrings — `LIKE '%…%'` — over names, codes, email, phone digits, and registration numbers. A B-tree cannot serve that, and a platform operator's search spans every tenant, so `tenant_id`-leading indexes cannot narrow it either (ADR-0018). `V19__platform_search.sql` adds `pg_trgm` GIN indexes on exactly the expressions the search predicates use:

| Table | Indexed expressions |
|---|---|
| `students` | full name (`lower(first_name` · `' '` · `last_name)`), `lower(admission_no)` |
| `guardians` | full name, phone digits (`regexp_replace(phone, '[^0-9]', '', 'g')`), `lower(email)` |
| `transport_staff` | full name, phone digits, `lower(employee_code)` |
| `vehicles` | `lower(display_name)`, `lower(registration_no)`, registration letters and digits only |
| `routes` | `lower(name)`, `lower(code)` |
| `schools` | `lower(name)`, `lower(code)` |
| `users` | full name, `lower(email)`, phone digits |

Trigram indexes serve patterns of 3 or more characters — the minimum `SearchQuery` enforces. **An expression changed in the search SQL must change in the index too**, or the index silently stops being used. They add write cost on insert, most visible during bulk student import.

---

## Partial Indexes

Used heavily, because most hot queries filter on a small active subset:

```sql
CREATE INDEX idx_trips_active ON trips (tenant_id, school_id, status)
    WHERE status IN ('STARTED', 'IN_PROGRESS');
```

At any moment a tiny fraction of trips are active, a tiny fraction of alerts are open, and a tiny fraction of deliveries are pending. Partial indexes on those predicates are a fraction of the size of full indexes and stay in cache.

---

## Partitioning: `position_history`

The only partitioned table. It is ~99% of row volume and 0% of business logic ([`DATA_MODEL_OVERVIEW.md`](DATA_MODEL_OVERVIEW.md)).

```sql
CREATE TABLE position_history (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL,
    vehicle_id  UUID        NOT NULL,
    trip_id     UUID,
    latitude    NUMERIC(9,6) NOT NULL,
    longitude   NUMERIC(9,6) NOT NULL,
    speed_mps   NUMERIC(6,2),
    heading_deg INTEGER,
    ignition_on BOOLEAN,
    device_time TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, received_at)
) PARTITION BY RANGE (received_at);
```

**Daily range partitions on `received_at`.**

- `received_at`, not `device_time` — a device buffering through a coverage gap can report hours-old positions, and partitioning on device time would write into old partitions unpredictably.
- The primary key includes the partition key, as PostgreSQL requires.
- Per-partition index: `(tenant_id, vehicle_id, received_at)` and `(tenant_id, trip_id, received_at)`.

### Why daily

| Interval | Assessment |
|---|---|
| Hourly | Too many partitions; planning overhead grows |
| **Daily** | **Chosen.** Aligns with the service day; retention drops are granular; ~17M rows/partition at reference scale |
| Monthly | Partitions too large to drop granularly; retention becomes coarse |

### Lifecycle

Managed by a scheduled job, not migrations ([`MIGRATION_STRATEGY.md`](MIGRATION_STRATEGY.md)):

```
Daily job:
  1. Create partitions for the next N days (N > 1, so one failed run is not an outage)
  2. APPLY RLS to each new partition       ← mandatory, RLS is not inherited
  3. Create indexes on each new partition
  4. Drop partitions past retention        BR-TRACK-007
  5. Alert if the next partition is missing
```

**Step 2 is the one that must never be missed.** A partition created without a policy exposes every tenant's vehicle positions for that day. Verification test 8 in [`RLS_POLICIES.md`](RLS_POLICIES.md) covers it.

**Step 5 matters because a missing partition breaks ingestion** — the insert has nowhere to go. The alert fires with days of margin.

### Pruning

Queries must filter on `received_at` to prune. Repositories always include a time range; a history query without one is a defect, caught by a test asserting single-day queries touch a single partition.

---

## Tables Deliberately Not Partitioned

| Table | Rows/year | Why not |
|---|---|---|
| `boarding_events` | ~150M | Queried by student and by trip across arbitrary time ranges; partitioning would hurt those more than it helps. Revisit if size becomes the constraint. |
| `audit_records` | ~190M | Retention is long and legally bounded; queries are by subject and actor, not by time range. |
| `notifications` | ~150M | Short practical query window; archival is simpler than partitioning. |

Each has a documented trigger for reconsideration ([`SCALABILITY.md`](SCALABILITY.md)).

---

## Maintenance

Autovacuum tuned more aggressively on high-churn tables (`trips`, `notification_deliveries`, `alerts`). `position_history` partitions are effectively append-only and need little vacuuming, but are `ANALYZE`d after creation so the planner has statistics.

Index bloat and unused indexes are reviewed periodically — an unused index costs write throughput on every insert at peak.

---

## Verification

1. Every tenant-scoped index leads with `tenant_id`.
2. A single-day history query touches exactly one partition (pruning works).
3. A newly created partition has RLS enabled, forced, and policied.
4. Every hot-path query in the repository layer has a supporting index — query plans asserted in integration tests.
5. The partition job creates ahead and alerts when the next partition is absent.
6. `boarding_events.client_event_id` uniqueness rejects a duplicate replay.
