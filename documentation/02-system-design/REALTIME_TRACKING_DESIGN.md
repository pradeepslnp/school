# REAL-TIME TRACKING DESIGN

**Document tier:** 2 — System Design
**Status:** Active
**Implements:** ADR-0004 · **Enforces:** BR-TRACK-*, BR-ALERT-*

---

## Pipeline

```
GPS Device
   │  vendor protocol (TCP, HTTP, MQTT)
   ▼
┌──────────────────┐
│ Device Adapter   │  implements PositionSource port
└────────┬─────────┘
         ▼
┌──────────────────┐
│ Ingestion        │  authenticate device → resolve vehicle → validate
└───┬──────────┬───┘
    │          │
    ▼          ▼
┌────────┐  ┌──────────────────┐
│ Redis  │  │ position_history │  batched, day-partitioned
│ latest │  └──────────────────┘
└───┬────┘         │
    │              ▼
    │      ┌──────────────────┐
    │      │ Event Processor  │  geofence · deviation · speed · ETA
    │      └────────┬─────────┘
    │               ▼
    │      ┌──────────────────┐
    │      │  Alerts + Domain │──► Notification
    │      │     Events       │
    │      └──────────────────┘
    ▼
┌──────────────────┐
│ WebSocket/STOMP  │──► parent app, admin web
└──────────────────┘
```

---

## Device Adapters

Devices differ in protocol, field names, units, and coordinate conventions. That variety is confined to adapters (ADR-0004).

```java
public interface PositionSource {
    /** Normalises a vendor payload into the canonical report, or empty if unparseable. */
    Optional<PositionReport> parse(RawDeviceMessage message);
}
```

`PositionReport` is canonical: device identifier, coordinates, speed (m/s), heading, ignition state, device timestamp, accuracy.

**Adding a vendor is a new adapter and a configuration row — never a change to ingestion, processing, or domain code.** A test asserts no ingestion class references a vendor name.

---

## Validation

Rejected reports are logged and dropped, never stored as fact (BR-TRACK-004):

| Check | Rejects |
|---|---|
| Coordinate range | Out-of-range latitude/longitude, null-island `0,0` |
| Speed plausibility | Above a configured maximum |
| Implied speed | Distance from previous fix over elapsed time exceeding a threshold — catches teleporting fixes |
| Timestamp sanity | Future beyond clock-skew tolerance, or implausibly old |
| Accuracy | Below a configured confidence floor |
| Known device | Unregistered or unassigned device logged and ignored (BR-FLEET-006) |

**Ordering:** reports can arrive out of order after a device buffers through a coverage gap. Live position updates only if the report's timestamp is newer than the cached one; history accepts any valid report and orders on read.

---

## Live Position (Hot Path)

Redis, one key per vehicle:

```
Key    livepos:{tenantId}:{vehicleId}
Value  { lat, lon, speed, heading, ignition, deviceTime, receivedAt, tripId }
TTL    configurable, comfortably above the expected report interval
```

Reads never touch PostgreSQL. TTL expiry is meaningful: an absent key means "not currently reporting", which is exactly what a stale-position indicator needs (BR-TRACK-003).

**Redis loss degrades live tracking but loses no data** — history writes are independent, and the cache repopulates on the next report (ADR-0004).

---

## Position History (Cold Path)

`position_history`, partitioned by day ([`INDEXING_AND_PARTITIONING.md`](../03-database/INDEXING_AND_PARTITIONING.md)).

- Written in batches — per-report inserts would not survive peak load.
- Retention by dropping partitions, not deleting rows (BR-TRACK-007).
- Partitions created ahead by a scheduled job; **a missing future partition breaks ingestion**, so its absence alerts.

---

## Event Processing

Asynchronous — a slow geofence evaluation must never delay ingestion acknowledgement.

| Evaluation | Rule | Notes |
|---|---|---|
| Stop geofence entry | BR-ALERT-001 | Triggers approach and arrival notifications |
| School geofence | ALT-003 | Arrival and departure |
| Route deviation | BR-ALERT-002 | Corridor distance sustained beyond a duration |
| Overspeed | BR-ALERT-003 | Speed sustained beyond a duration, not instantaneous |
| Unscheduled stop | BR-ALERT-004 | Stationary outside a defined stop |
| Signal loss | BR-TRACK-005 | Absence of reports during an active trip |

**Sustained-condition checks matter.** An instantaneous speed spike from a bad fix is not overspeed; a momentary GPS wander is not a deviation. Every threshold has both a magnitude and a duration, and both are tenant configuration bounded by platform floors (BR-CFG-003).

**Deduplication** (BR-ALERT-005): a continuing condition holds one open alert. Alerts resolve when the condition clears or an owner resolves them (BR-ALERT-006).

---

## ETA

Inputs: current position, remaining route path, historical segment times for this route, time of day.

**ETA is always presented as an estimate with its calculation time** (BR-TRACK-006). The platform never states an arrival time as fact — a parent who leaves the house on a wrong ETA and misses the bus is a product failure.

Recalculated on each position report; published to subscribers for the affected stop.

---

## Client Delivery

WebSocket/STOMP. Clients subscribe per trip.

```
Client connects → JWT authenticated
Client subscribes /topic/trip/{tripId}
   ▼
Authorisation checked AT SUBSCRIBE TIME
   • guardian: is one of their children on this trip's manifest?  BR-TRACK-002
   • staff/manager: is the trip in scope?
   ▼
Subscription accepted → position and ETA updates pushed
   ▼
Trip reaches COMPLETED → subscriptions closed
```

**Subscription authorisation is the control that matters here.** An unchecked topic subscription would expose any vehicle's live position to anyone who could guess a trip ID.

**Tracking is trip-scoped** (BR-TRACK-001): vehicles are not tracked outside trip windows, and no subscription exists for a vehicle not on an active trip. This is what keeps the platform a safety tool rather than staff surveillance ([`STAKEHOLDERS.md`](../01-product-discovery/STAKEHOLDERS.md) conflicts).

Fallback: clients unable to hold a WebSocket poll a REST endpoint at a longer interval.

---

## Performance Budgets

| Stage | Target |
|---|---|
| Ingestion acknowledgement | p95 < 100 ms |
| Position visible in live cache | p95 < 500 ms from receipt |
| Geofence event raised | p95 < 3 s from receipt |
| Notification dispatched from event | p95 < 5 s |
| **Board/alight notification, end to end** | **p95 < 10 s** (charter measure) |
| Live position freshness at client | p95 < 30 s (charter measure) |

---

## Verification

1. Sustained ingestion at 3× projected peak stays within acknowledgement budget.
2. With Redis stopped, positions still persist and no ingestion request fails.
3. Out-of-order reports do not move live position backwards; history retains all.
4. Implausible reports are rejected and logged, not stored.
5. A subscriber without permission cannot subscribe to a trip topic.
6. No position is served for a vehicle outside an active trip.
7. A continuing deviation produces one alert, not a stream.
8. Missing future partition triggers an alert before ingestion is affected.
