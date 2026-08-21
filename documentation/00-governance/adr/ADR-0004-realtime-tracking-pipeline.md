# ADR-0004: Real-time tracking pipeline

**Status:** Proposed
**Date:** 2026-08-03
**Affects:** tracking module, [`REALTIME_TRACKING_DESIGN.md`](../../02-system-design/REALTIME_TRACKING_DESIGN.md), [`INDEXING_AND_PARTITIONING.md`](../../03-database/INDEXING_AND_PARTITIONING.md)

## Context

Vehicles report position every 10–30 seconds while on a trip. For 1,000 active vehicles at 10-second intervals that is ~100 writes/second sustained, concentrated in two sharp peaks per school day (morning pickup, afternoon drop) — a load profile that is bursty rather than uniform.

Two very different read patterns sit on the same data:

- **Hot:** "where is bus 12 right now" — read constantly by parents during a trip, needs the latest point only, needs to be fast.
- **Cold:** "reconstruct yesterday's route for an incident investigation" — rare, needs the full series, latency-tolerant.

Storing both in one table and serving both from it makes the hot path pay for the cold path's volume.

## Decision

**Split the hot and cold paths behind a single ingestion endpoint.**

```
GPS device
   │  (device-specific protocol)
   ▼
Device Adapter ──► Ingestion Service ──┬──► Redis  (live position, per vehicle, TTL)
   (port/adapter)      │               │
                       │               └──► position_history (partitioned by day)
                       ▼
              Event Processor
        (geofence, deviation, speed, ETA)
                       │
                       ▼
            Domain events ──► Notification Engine
                           └► WebSocket/STOMP ──► parent & admin clients
```

- **Device adapters** implement a common `PositionSource` port. Adding a device vendor is a new adapter, never a change to ingestion.
- **Redis** holds the latest position per vehicle. Reads for live tracking never touch PostgreSQL.
- **`position_history`** is a PostgreSQL table partitioned by day, written in batches, retained per tenant policy.
- **Event processing** is asynchronous. A slow geofence evaluation must never delay ingestion acknowledgement.
- **Clients** receive live updates over WebSocket/STOMP, subscribed per trip and authorisation-checked at subscribe time.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| PostgreSQL only, no cache | Simplest. Rejected because live-position reads scale with the number of watching parents, not vehicles — a popular morning route means thousands of reads/second against the largest table in the system. |
| Kafka as the ingestion backbone | The right answer at an order of magnitude more traffic. Rejected today under KISS: it adds a cluster to operate for a load a well-tuned service handles. The `PositionSource` port keeps this migration open. |
| TimescaleDB | A genuinely good fit for this workload, and the closest call here. Rejected only to keep the deployment to stock PostgreSQL, which matters for managed-database portability. Native declarative partitioning covers the current requirement. **Revisit if history query performance becomes the constraint.** |
| Client polling instead of WebSocket | Simpler, but polling at the freshness target (<30s p95) across many parents produces more load than persistent connections, and drains phone batteries. |

## Consequences

**Positive**
- Hot reads are O(1) against Redis and independent of history volume.
- History growth is managed by dropping partitions rather than deleting rows.
- New device vendors are additive.

**Negative / accepted cost**
- Redis becomes a runtime dependency for live tracking. **Its loss degrades live tracking but must not lose data** — positions are still durably written, so the system recovers on the next report.
- Two storage systems mean two operational concerns.
- Asynchronous processing means geofence alerts trail ingestion slightly; the budget is defined in [`REALTIME_TRACKING_DESIGN.md`](../../02-system-design/REALTIME_TRACKING_DESIGN.md).
- Partition management requires automation; a missing future partition breaks ingestion. Covered by a scheduled job and an alert.

## Reversal Cost

**Low to moderate.** The `PositionSource` port and the separation of live cache from durable history mean Kafka or TimescaleDB can be introduced behind existing interfaces without touching the domain.

## Verification

1. Load test: sustained ingestion at 3× projected peak with p95 acknowledgement under budget.
2. A test asserts live tracking degrades gracefully — with Redis unavailable, positions are still persisted and no ingestion request fails.
3. A scheduled-job test asserts partitions exist ahead of time; alerting fires if the next partition is missing.
4. An authorisation test asserts a WebSocket subscriber cannot subscribe to a trip they lack permission to view.
