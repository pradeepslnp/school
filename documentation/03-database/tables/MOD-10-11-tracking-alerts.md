# MOD-10 / MOD-11 — Tracking & Alerts Tables

**Owning modules:** `com.guardian.tracking`, `com.guardian.alert` · **Implements:** ADR-0004 · **Rules:** BR-TRACK-*, BR-ALERT-*

---

## `position_history`

**The only partitioned table** — ~99% of row volume, 0% of business logic. Full rationale in [`INDEXING_AND_PARTITIONING.md`](../INDEXING_AND_PARTITIONING.md).

| Column | Type | Notes |
|---|---|---|
| `vehicle_id` | `UUID` | `NOT NULL` → `vehicles` |
| `trip_id` | `UUID` | → `trips`. Null only for a brief pre-trip window. |
| `device_id` | `UUID` | `NOT NULL` → `devices` |
| `latitude`, `longitude` | `NUMERIC(9,6)` | `NOT NULL` |
| `speed_mps` | `NUMERIC(6,2)` | SI units; converted at display |
| `heading_deg` | `INTEGER` | `0`–`359` |
| `accuracy_m` | `NUMERIC(6,2)` | |
| `ignition_on` | `BOOLEAN` | |
| `device_time` | `TIMESTAMPTZ` | `NOT NULL` — device clock |
| `received_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` — **partition key** |

```sql
PRIMARY KEY (id, received_at),
CONSTRAINT ck_position_latitude  CHECK (latitude  BETWEEN -90  AND 90),
CONSTRAINT ck_position_longitude CHECK (longitude BETWEEN -180 AND 180),
CONSTRAINT ck_position_heading   CHECK (heading_deg IS NULL OR heading_deg BETWEEN 0 AND 359)
) PARTITION BY RANGE (received_at);
```

**Partitioned on `received_at`, not `device_time`.** A device buffering through a coverage gap reports hours-old positions on reconnect. Partitioning on device time would scatter writes into old partitions unpredictably — including partitions already dropped by retention.

The primary key includes the partition key because PostgreSQL requires it.

**No standard audit columns.** These rows are machine-generated telemetry, written once, never updated, and dropped by partition. `created_by`/`updated_at`/`version` would add bytes to billions of rows for no purpose — **a documented deviation** from [`CONVENTIONS.md`](../CONVENTIONS.md).

**Validation happens before insert, not as constraints.** Plausibility checks — implied speed between fixes, timestamp sanity, accuracy floor — live in the ingestion service (BR-TRACK-004). Rejected reports are logged and dropped, never stored. The check constraints above are a last-resort guard against a coding error, not the primary control.

**Per-partition indexes:** `(tenant_id, vehicle_id, received_at)`, `(tenant_id, trip_id, received_at)`

**RLS must be applied to every new partition by the partition-creation job** — it is not inherited ([`RLS_POLICIES.md`](../RLS_POLICIES.md)).

---

## `trip_etas`

| Column | Type | Notes |
|---|---|---|
| `trip_id` | `UUID` | `NOT NULL` → `trips` |
| `stop_id` | `UUID` | `NOT NULL` → `stops` |
| `estimated_arrival` | `TIMESTAMPTZ` | `NOT NULL` |
| `calculated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |
| `confidence` | `VARCHAR(16)` | `NOT NULL`, `HIGH` / `MEDIUM` / `LOW` |

```sql
CONSTRAINT uq_trip_etas UNIQUE (tenant_id, trip_id, stop_id),
CONSTRAINT ck_trip_etas_confidence CHECK (confidence IN ('HIGH','MEDIUM','LOW'))
```

**`calculated_at` and `confidence` are both `NOT NULL`** because BR-TRACK-006 requires an ETA to be presented as an estimate, with its calculation time. A parent who leaves the house on a stale ETA and misses the bus is a product failure — the UI cannot present freshness or uncertainty it was not given.

`confidence` drops to `LOW` when routing is unavailable and straight-line fallback is used ([`INTEGRATION_ARCHITECTURE.md`](../../02-system-design/INTEGRATION_ARCHITECTURE.md)).

One row per trip-stop, upserted on recalculation. History is not retained — a superseded estimate has no evidentiary value.

---

## `alert_rules`

Tenant-configurable thresholds, bounded by platform floors (BR-CFG-003 🔴).

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | → `schools`. Null = organization-wide. |
| `rule_type` | `VARCHAR(32)` | `NOT NULL`, `OVERSPEED` / `ROUTE_DEVIATION` / `UNSCHEDULED_STOP` / `SIGNAL_LOSS` / `TRIP_DELAY` |
| `threshold_value` | `NUMERIC(10,2)` | `NOT NULL` — SI units |
| `duration_seconds` | `INTEGER` | `NOT NULL DEFAULT 0` |
| `severity` | `VARCHAR(16)` | `NOT NULL`, `LOW` / `MEDIUM` / `HIGH` / `CRITICAL` |
| `is_enabled` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT uq_alert_rules UNIQUE (tenant_id, school_id, rule_type),
CONSTRAINT ck_alert_rules_type CHECK (rule_type IN (
    'OVERSPEED','ROUTE_DEVIATION','UNSCHEDULED_STOP','SIGNAL_LOSS','TRIP_DELAY')),
CONSTRAINT ck_alert_rules_duration CHECK (duration_seconds >= 0),
CONSTRAINT ck_alert_rules_threshold CHECK (threshold_value > 0)
```

### `duration_seconds` is why alerts are usable

Every threshold has both a **magnitude and a duration**. An instantaneous speed spike from a bad GPS fix is not overspeed; a momentary positional wander is not a route deviation. Without the duration dimension, managers receive constant false alerts and stop reading them — which makes the real one invisible ([`PERSONAS.md`](../../01-product-discovery/PERSONAS.md), Anil).

Platform floors and ceilings are enforced in the configuration module (MOD-17), not here, because they vary by `rule_type` and cannot be expressed as a single check.

---

## `alerts`

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` |
| `trip_id` | `UUID` | → `trips` |
| `vehicle_id` | `UUID` | → `vehicles` |
| `alert_rule_id` | `UUID` | → `alert_rules` |
| `alert_type` | `VARCHAR(32)` | `NOT NULL` |
| `severity` | `VARCHAR(16)` | `NOT NULL` |
| `status` | `VARCHAR(16)` | `NOT NULL`, `OPEN` / `ACKNOWLEDGED` / `RESOLVED` |
| `detail` | `JSONB` | Measured value, threshold, position at detection |
| `opened_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |
| `last_observed_at` | `TIMESTAMPTZ` | `NOT NULL` — updated while the condition persists |
| `acknowledged_at`, `acknowledged_by` | | |
| `resolved_at`, `resolved_by`, `resolution_outcome` | | |

```sql
CONSTRAINT ck_alerts_status CHECK (status IN ('OPEN','ACKNOWLEDGED','RESOLVED')),
CONSTRAINT ck_alerts_resolved CHECK (
    status <> 'RESOLVED' OR (resolved_at IS NOT NULL AND resolution_outcome IS NOT NULL))
```

### Deduplication

`last_observed_at` is what implements BR-ALERT-005. A continuing condition **updates this field on an existing open alert** rather than inserting a new row. A bus deviating for twenty minutes produces one alert observed repeatedly — not two hundred rows.

Enforced by a partial unique index:

```sql
CREATE UNIQUE INDEX uq_alerts_open_condition
    ON alerts (tenant_id, trip_id, alert_type)
    WHERE status IN ('OPEN','ACKNOWLEDGED');
```

At most one unresolved alert per trip per type, structurally.

**`ck_alerts_resolved` implements BR-ALERT-006** — alerts are not silently dropped. Closing one requires an outcome, so "resolved" always means someone decided something.

**Indexes:** `idx_alerts_open (tenant_id, school_id, severity, opened_at DESC) WHERE status = 'OPEN'` — the transport manager's dashboard query, ordered by severity.

---

## Verification

1. A single-day history query touches exactly one partition.
2. A newly created partition has RLS enabled, forced, and policied.
3. An implausible position report is rejected before insert and logged.
4. Out-of-order reports do not move live position backwards; history retains all.
5. A continuing deviation produces one alert row with an advancing `last_observed_at`.
6. A second open alert of the same type for the same trip is rejected by the partial unique index.
7. Resolving an alert without an outcome is rejected.
8. An ETA row cannot be written without `calculated_at` and `confidence`.
