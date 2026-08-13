# SCALABILITY

**Document tier:** 2 — System Design
**Status:** Active
**Implements:** charter commitment "works for one school and for a group of five hundred"

---

## The Load Profile

School transport load is **bimodal and predictable**, unlike most SaaS:

```
Load
 │      ██                              ██
 │      ██                              ██
 │      ██                              ██
 │     ████                            ████
 │  ▁▁██████▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁██████▁▁▁▁▁▁▁▁
 └────────────────────────────────────────────────► time
     06:30  08:30              14:00  16:00
```

Two peaks of roughly two hours, near-zero between, nothing on weekends and holidays.

**This shapes every decision below.** The system must handle 3× peak, and idle cheaply. Optimising for average load would be optimising for a state the system is rarely in.

---

## Reference Scale

| Dimension | R1 target | Design headroom |
|---|---|---|
| Organizations | 50 | 500 |
| Schools | 200 | 2,000 |
| Students | 200,000 | 2,000,000 |
| Vehicles | 3,000 | 30,000 |
| Concurrent trips at peak | 2,000 | 20,000 |
| Position reports/sec at peak | 200 | 2,000 |
| Notifications/min at peak | 5,000 | 50,000 |
| Concurrent WebSocket subscribers | 20,000 | 200,000 |

Headroom is one order of magnitude. Beyond that, the ADRs deliberately left doors open — Kafka for ingestion (ADR-0004), schema-per-tenant for the largest customers (ADR-0001).

---

## Scaling by Component

### API
Stateless; scales horizontally. Bottleneck is **database connections**, not CPU. Sessions are token-based, so no sticky routing is needed except for WebSocket, which uses a shared broker relay rather than affinity.

### Ingestion
Scales on active vehicles × report rate. Separate deployable precisely so a device storm cannot degrade the parent app ([`ARCHITECTURE_OVERVIEW.md`](ARCHITECTURE_OVERVIEW.md)). Writes are batched — per-report inserts would not survive peak.

### Worker
Scales on notification volume. The real ceiling is **provider rate limits**, not the platform. Bulkheaded pools per channel so one slow provider cannot starve the others.

### PostgreSQL
Single primary for writes; read replicas for reporting (BR-RPT-004 — reporting must never block operational writes).

`position_history` dominates volume and is partitioned by day, so it is dropped rather than deleted (BR-TRACK-007). Excluding it, the operational dataset is modest — student and trip data at reference scale is comfortably within a single primary.

### Redis
Memory scales with active vehicles; live positions carry a TTL. Loss degrades tracking but loses no data (ADR-0004).

---

## Query Patterns That Matter

| Query | Frequency | Approach |
|---|---|---|
| Live position for a trip | Very high at peak | Redis only; never touches PostgreSQL |
| Guardian's children's trips today | Very high at peak | Indexed on `(tenant_id, guardian_id, date)`; short-TTL cache |
| Trip manifest | High | Materialised at trip start (BR-TRIP-003), cached for the trip's life |
| Reconciliation at trip close | Per trip | Bounded by manifest size |
| Position history replay | Rare | Partition-pruned by date |
| Reporting aggregates | Scheduled | Read replica; pre-aggregated where hot |

**Every index leads with `tenant_id`** — the RLS predicate applies to every query ([`MULTI_TENANCY.md`](MULTI_TENANCY.md)).

---

## Caching

| Cache | TTL | Invalidation |
|---|---|---|
| Live position | Short, above report interval | Overwritten by next report |
| Resolved permissions | Seconds | On role change (BR-IAM-004) |
| Tenant configuration | Minutes | On configuration change |
| Trip manifest | Trip lifetime | On manifest amendment |
| Route and stop definitions | Hours | On route change |

Permission cache TTL is deliberately short. A longer TTL would improve throughput and weaken the revocation guarantee ADR-0006 exists to provide — safety outranks throughput.

---

## Multi-Tenant Fairness

One tenant must not degrade another:

- Rate limits per tenant as well as per user and per IP.
- Ingestion limits per device.
- Reporting and export jobs are queued with per-tenant concurrency caps.
- Bulk imports are chunked and throttled.
- Notification dispatch is fair-queued across tenants — a group sending 50,000 messages cannot delay another school's `CRITICAL` alert.

That last point is safety-relevant, not merely polite.

---

## Cost Shape

Idle cost matters when the system is idle most of the day.

- Autoscale API and worker on the daily schedule; the peaks are known in advance, so scaling can be **predictive rather than reactive** — reactive scaling lags a peak that arrives in minutes.
- Ingestion scales with active trips, which is naturally near-zero off-peak.
- Position history is the dominant storage cost and is controlled by retention.

---

## Known Limits and Their Triggers

| Limit | Trigger to act | Action |
|---|---|---|
| Single write primary | Sustained write saturation at peak | Partition further; consider write sharding by tenant |
| Position volume | History queries degrade despite pruning | Adopt TimescaleDB (ADR-0004 alternative) |
| Ingestion throughput | Backpressure at 3× peak | Adopt Kafka behind `PositionSource` (ADR-0004) |
| Largest tenant dominance | One tenant's volume affects others | Schema or database separation for that tenant (ADR-0001) |
| WebSocket fan-out | Broker saturation | External broker relay, already the deployment shape |

Each limit has a **named successor already documented in an ADR**. None requires a redesign — which is the actual scalability claim being made here.

---

## Verification

1. Load test at 3× projected peak across ingestion, API, and notification; all budgets in [`REALTIME_TRACKING_DESIGN.md`](REALTIME_TRACKING_DESIGN.md) hold.
2. A tenant generating extreme load does not degrade another tenant's p95 latency.
3. Reporting queries against a replica do not affect operational write latency.
4. Partition pruning verified: a history query for one day does not scan other partitions.
5. Every tenant-scoped query plan uses an index leading with `tenant_id`.
