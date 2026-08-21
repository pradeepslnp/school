# ADR-0005: Provider-abstracted notification channels

**Status:** Proposed
**Date:** 2026-08-03
**Affects:** notification module, [`NOTIFICATION_ARCHITECTURE.md`](../../02-system-design/NOTIFICATION_ARCHITECTURE.md), [`NOTIFICATION_CATALOG.md`](../../01-product-discovery/NOTIFICATION_CATALOG.md)

## Context

Notification is the product's main output to parents — [`PRODUCT_PRINCIPLES.md`](../../PRODUCT_PRINCIPLES.md) §2 makes it a first-class concern, not plumbing.

Constraints:

- SMS providers are regional and change; a customer in a new country may require a different provider, and some markets impose registration requirements on templates and sender IDs.
- Parents span device quality and connectivity. Push alone is insufficient; SMS is the reliable floor.
- Some events are safety-critical and must ignore user preferences and quiet hours (`BR-NTF-006`).
- Notification volume is bursty and concentrated at the same peaks as tracking.

Hardcoding a provider would violate [`PRODUCT_PRINCIPLES.md`](../../PRODUCT_PRINCIPLES.md) §5 directly: onboarding a customer in a new country would require a code change.

## Decision

**A single `NotificationChannel` port with per-provider adapters, selected by tenant configuration at runtime.**

```
Domain event
   ▼
Notification Engine
   ├─ resolve recipients      (guardians, staff — by event type and scope)
   ├─ apply preferences       (skipped for safety-critical events)
   ├─ render template         (tenant + locale + channel)
   └─ dispatch ──► NotificationChannel port
                     ├── PushChannel      (FCM adapter)
                     ├── SmsChannel       (provider adapters, per tenant)
                     ├── EmailChannel     (SMTP / provider adapters)
                     └── InAppChannel     (persisted, read-tracked)
```

- Channel selection, provider credentials, sender IDs, and template registrations are **tenant configuration**.
- Templates are versioned data with locale variants, not code.
- Every dispatch attempt is recorded with status, provider reference, and failure reason — delivery is auditable.
- Retry with backoff per channel; failure on one channel escalates to a fallback channel for safety-critical events.
- Outbound dispatch is asynchronous and queued; a slow provider must never block a domain transaction.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Direct provider SDK calls in services | Fastest to build; violates §5, couples domain to vendor, untestable without network. |
| A third-party notification aggregator | Attractive — one integration, many channels. Rejected as the sole mechanism because it adds a dependency in the safety-critical path and constrains regional SMS compliance. Not excluded: an aggregator can be *one adapter* behind the port. |
| Push only | Cheapest, but excludes parents on low-end devices and poor connectivity, violating [`PRODUCT_PRINCIPLES.md`](../../PRODUCT_PRINCIPLES.md) §6. |

## Consequences

**Positive**
- A new country or provider is a configuration change plus, at most, one new adapter.
- Channels are testable with in-memory fakes; no network in unit tests.
- Delivery outcomes are auditable, which matters when a parent asks why they were not told.

**Negative / accepted cost**
- More indirection than calling an SDK. Justified: the second and third implementations are known to exist, not hypothetical.
- Per-tenant provider credentials require secure storage and rotation.
- Template management needs an admin surface — real product scope, not incidental.

**Neutral**
- Delivery *receipts* vary in fidelity by provider; the model records what the provider reports and does not pretend to more certainty than it has.

## Reversal Cost

**Low.** The port is the abstraction; adapters are replaceable individually.

## Verification

1. A test asserts no domain or application class imports a provider SDK.
2. A test asserts safety-critical events dispatch even when the recipient has disabled that event and quiet hours are active (`BR-NTF-006`).
3. A test asserts a failing primary channel escalates to fallback for safety-critical events and records both attempts.
4. Contract tests per adapter against a recorded provider fixture.
