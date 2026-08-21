# ADR-0008: Offline-first driver application

**Status:** Proposed
**Date:** 2026-08-03
**Affects:** `flutter/driver_attender_app/`, boarding module, [`DRIVER_ATTENDANT_APP.md`](../../05-ui/DRIVER_ATTENDANT_APP.md)

## Context

[`PROJECT_CHARTER.md`](../../PROJECT_CHARTER.md) §6.5 commits that *loss of connectivity on a vehicle must not lose safety data.*

School routes pass through areas with no coverage. The driver app records the platform's most important data — boarding events and handovers — and it records them precisely where connectivity is least reliable. An app that requires a network to record a boarding event will fail during the exact minutes it matters.

Additionally: a boarding record created offline still needs a trustworthy timestamp, and the device clock is under the user's control.

## Decision

**The driver/attendant app is offline-first. The local database is the primary write target; synchronisation is a background concern.**

- **Local-first writes.** Boarding, alighting, handover, and incident records are written to an encrypted local store and acknowledged in the UI immediately. The user is never blocked on a network call for a safety action.
- **Trip data is pre-loaded.** On trip start, the full manifest — students, stops, guardians, authorised pickup persons, verification material — is cached so the trip runs entirely offline if needed.
- **Durable outbound queue.** Pending records survive app restart and device reboot, syncing opportunistically.
- **Idempotency.** Every record carries a client-generated UUID; the server deduplicates on it. Retries are safe.
- **Two timestamps, always.** `occurred_at` (device clock, with a recorded clock-skew estimate) and `recorded_at` (server receipt). Reports use `occurred_at`; investigations can see both. **The device clock is never trusted as authoritative** — skew is measured against server time on each sync and stored with the record.
- **Conflict policy.** Safety events are append-only and never conflict. Where server state contradicts a client action (a student marked absent after the manifest was cached), the record is accepted and **flagged for review** rather than rejected — losing a real safety record is worse than storing a questionable one.
- **Visible sync state.** The attendant always sees how many records are pending and whether the device is offline. Silent queuing hides failure.
- **Bounded staleness.** If the manifest exceeds a configured age, the app warns; it does not lock out.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Online-only with a spinner | Simplest by a wide margin. Rejected outright: it loses safety data in exactly the conditions the charter names. |
| Online-first with a small retry buffer in memory | Handles brief blips. Rejected: an app restart or a battery pull loses the buffer, and coverage gaps on rural routes last minutes, not seconds. |
| Full bidirectional sync framework (CRDT-based) | Powerful, but the write model here is append-only events from a single device per trip. CRDTs solve a concurrency problem this domain does not have. Violates KISS. |
| Trust the device clock as authoritative | Rejected: device clocks drift and can be changed by the user. In a system whose records may be examined after an incident, timestamp provenance must be explicit. |

## Consequences

**Positive**
- Safety data survives coverage gaps, app crashes, and reboots.
- The UI is fast — no network latency in the boarding flow, which matters when children are queueing to board.
- Retries are safe by construction.

**Negative / accepted cost**
- Significant complexity: local schema, migrations, queue, and sync are real engineering scope with their own tests.
- **Data at rest on the device is child PII.** Requires encryption, and wipe on logout or session revocation.
- Cached manifests can be stale; the flag-for-review path exists precisely because of this and produces work for staff.
- Two timestamps complicate reporting; documentation must be clear about which is used where.

**Neutral**
- The parent app is **not** offline-first. It is a read surface; stale data there is a display problem, not a data-loss problem.

## Reversal Cost

**High.** Offline-first is an architectural property of the app, not a feature. It is far cheaper to build this way from the start than to retrofit — which is why this ADR exists before the driver app is written.

## Verification

1. A test records a full trip's boarding events with the network disabled, restarts the app, restores connectivity, and asserts every event reaches the server exactly once.
2. A test asserts replaying the same client UUID does not create a duplicate server record.
3. A test asserts a device clock skewed by hours still produces a record whose skew is measured and stored, and that server-side reconciliation flags it.
4. A test asserts local storage is encrypted and cleared on logout and on remote session revocation.
5. A test asserts an action contradicting server state is accepted and flagged, not discarded.
