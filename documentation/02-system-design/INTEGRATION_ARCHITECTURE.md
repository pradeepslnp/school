# INTEGRATION ARCHITECTURE

**Document tier:** 2 — System Design
**Status:** Active
**Implements:** ADR-0004, ADR-0005, ADR-0007

Every external dependency sits behind a port defined in the application layer. No domain or application class names a vendor — verified by an architecture test.

---

## Integration Inventory

| Integration | Port | Criticality | Failure behaviour |
|---|---|---|---|
| GPS devices | `PositionSource` | High | Live tracking degrades; **boarding unaffected** |
| Push (FCM) | `NotificationChannel` | High | Fallback to SMS for `CRITICAL` |
| SMS (per-tenant provider) | `NotificationChannel` | **Critical** | The floor channel; failure escalates to staff |
| Email | `NotificationChannel` | Low | Retry; administrative only |
| Maps: tiles | client-side | Medium | Map blank; tracking data still readable as text |
| Maps: geocoding | `GeocodingService` | Low | Manual coordinate entry |
| Maps: routing | `RoutingService` | Medium | Straight-line fallback for ETA and deviation |
| School MIS import | file-based | Low | Manual import path remains |

**Ranking note:** SMS is the most critical outbound integration, not push. Push depends on an app being installed, a token being fresh, and a device being reachable; SMS reaches any phone ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §6).

---

## GPS Devices

Inbound, machine-authenticated, high volume. See [`REALTIME_TRACKING_DESIGN.md`](REALTIME_TRACKING_DESIGN.md).

- **Authentication:** device credential, mutual TLS where the device supports it. Never the human auth path (ADR-0006).
- **Adapters** normalise vendor payloads to a canonical `PositionReport`. Adding a vendor is a new adapter plus a configuration row.
- **Unknown devices** are logged and ignored, never auto-registered (BR-FLEET-006). Auto-registration would let anyone inject positions for a vehicle they do not own.
- **Rate limited per device** — one malfunctioning unit cannot flood ingestion.

---

## Notification Providers

Outbound, per-tenant configured (ADR-0005). See [`NOTIFICATION_ARCHITECTURE.md`](NOTIFICATION_ARCHITECTURE.md).

Regional SMS regimes vary — sender-ID registration, template pre-approval, opt-out handling. All of it is region-profile and tenant configuration (ADR-0007), never a code branch.

Provider credentials are encrypted at rest and are **never returned by any API**, including to the tenant that set them.

---

## Map and Routing

Client-side tiles; server-side geocoding and routing behind ports.

Routing serves ETA (BR-TRACK-006) and route-corridor calculation for deviation detection (BR-ALERT-002). On failure, both degrade to straight-line approximation, and ETA is presented with reduced confidence rather than withheld — a rough estimate labelled as rough is more useful to a waiting parent than nothing.

Tile provider is configurable; no provider is hardcoded in client code.

---

## School MIS Import

Schools hold student data in existing systems. R1 supports file import (STU-002) with per-row validation and a downloadable error report — the file is never rejected wholesale ([`PERSONAS.md`](../01-product-discovery/PERSONAS.md), Fatima).

A live MIS API integration is deliberately **not** in R1. Doing it properly requires a per-vendor mapping layer and a conflict policy for records edited on both sides; that needs its own ADR. Import remains available regardless, so no tenant is blocked.

---

## Resilience Patterns

Applied uniformly to every outbound integration:

| Pattern | Application |
|---|---|
| Timeout | Every call. No unbounded waits — a hung provider call must never occupy a request thread. |
| Retry with backoff | Transient failures only; bounded attempts; jittered. |
| Circuit breaker | Repeated failure opens the circuit; probes for recovery. Prevents one dead provider consuming the worker pool. |
| Bulkhead | Separate pools per integration, so SMS trouble cannot starve push. |
| Idempotency | Provider references recorded; retries do not double-send. |
| Fallback | Defined per integration in the table above. |

**No outbound call happens inside a business transaction.** Dispatch is enqueued and performed by the worker after commit — otherwise a slow provider would hold a database transaction open, and a provider outage would become a database outage.

---

## Adding an Integration

1. Define the port in the application layer, in the language of the domain — not the vendor's.
2. Implement the adapter in infrastructure.
3. Add configuration keys with types and defaults (BR-CFG-001).
4. Define the failure behaviour and record it in the inventory above.
5. Write a contract test against a recorded provider fixture.
6. Add metrics and alerting for its failure rate.
7. If the integration processes child data, record it in [`SECURITY_ARCHITECTURE.md`](SECURITY_ARCHITECTURE.md) and confirm the data-protection position.

## Verification

1. No domain or application class imports a vendor SDK.
2. Every outbound integration has a timeout, retry policy, and circuit breaker configured.
3. No outbound call occurs within a business transaction.
4. Each adapter has a contract test against a recorded fixture.
5. Provider credentials are never present in any API response.
6. A simulated provider outage degrades per the documented fallback and raises the expected alert.
