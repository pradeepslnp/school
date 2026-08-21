# NOTIFICATION ARCHITECTURE

**Document tier:** 2 — System Design
**Status:** Active
**Implements:** ADR-0005 · **Enforces:** BR-NTF-*, BR-SAFE-004 · **Catalog:** [`NOTIFICATION_CATALOG.md`](../01-product-discovery/NOTIFICATION_CATALOG.md)

---

## Pipeline

```
Domain event  (published after commit)
      ▼
┌─────────────────────────────────────────────┐
│ 1  Resolve notification definition          │  catalog ID + priority class
│ 2  Resolve recipients        BR-NTF-001     │  by RIGHT, never role alone
│ 3  Apply preferences         BR-NTF-003     │  ← skipped for CRITICAL
│ 4  Apply quiet hours         BR-NTF-004     │  ← skipped for CRITICAL
│ 5  Select channels                          │  per preference / class
│ 6  Render template           BR-NTF-002     │  tenant × locale × channel
│ 7  Enqueue dispatch                         │  durable queue
└──────────────────┬──────────────────────────┘
                   ▼
        ┌──────────────────────┐
        │ NotificationChannel  │  port
        └──┬────┬────┬─────┬───┘
           ▼    ▼    ▼     ▼
         Push  SMS  Email  InApp
           │    │    │     │
           ▼    ▼    ▼     ▼
      Delivery records — every attempt, every outcome   BR-NTF-005
```

Steps 3 and 4 are the only conditional ones, and `CRITICAL` skips both (BR-NTF-006). Everything else runs identically for every notification.

---

## Recipient Resolution

**By right, never by role** (BR-NTF-001). A transport manager is not notified about a specific child because they are a manager; they are notified because the notification definition names their role for that event class and their scope includes the trip.

```
Guardian recipients  = active guardian links
                       ∧ holds "receive notifications" right
                       ∧ no restriction blocking visibility     BR-GRD-008
Staff recipients     = role named in the definition
                       ∧ scope includes the subject
```

**Multi-recipient safety** (BR-NTF-007): a notification sent to more than one family — a trip-wide incident, for example — may not interpolate any student name. Enforced by a test asserting multi-recipient templates cannot reference student-name variables.

---

## Channels

```java
public interface NotificationChannel {
    ChannelType type();
    boolean supports(Recipient recipient);
    DeliveryResult send(RenderedNotification notification, Recipient recipient);
}
```

| Channel | Provider | Notes |
|---|---|---|
| Push | FCM adapter | Primary for app users; silent failure if token stale — hence delivery records |
| SMS | Per-tenant provider adapter | The reliable floor; works on any phone ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §6) |
| Email | SMTP or provider adapter | Administrative and reporting |
| In-app | Internal, persisted | Read-tracked; the durable record a parent can scroll back through |

Provider selection, credentials, and sender identity are **tenant configuration** (ADR-0007). No domain or application class imports a provider SDK — verified by test.

---

## Templates

Data, not code (BR-CFG-005). Keyed by `(tenant, notificationId, channel, locale)`, versioned, with variables declared and validated.

Resolution: tenant + locale → tenant + default locale → platform default for locale → platform default. A fallback beyond the first step logs a template gap so it can be filled (BR-NTF-002).

Rendering escapes all interpolated values (BR-NTF-008). Channel constraints are enforced at render time — SMS length, push payload limits — rather than discovered at the provider.

---

## Priority Classes

| Class | Preferences | Quiet hours | Channels | Retry |
|---|---|---|---|---|
| 🔴 `CRITICAL` | ignored | ignored | all available | aggressive + **fallback channel** |
| 🟠 `URGENT` | channel choice only | ignored | push + SMS | standard |
| 🟡 `STANDARD` | respected | deferred | per preference | standard |
| ⚪ `INFO` | respected | deferred | in-app, optional push | minimal |

**Quiet hours defer; they never discard** (BR-NTF-004). A suppressed standard notification is delivered when quiet hours end, not dropped.

---

## Delivery, Retry, Escalation

Every attempt writes a delivery record: notification, recipient, channel, provider reference, status, failure reason, timestamp. This is what lets the platform answer *"why was I not told?"* — a question that will be asked after an incident.

```
Attempt → success                        → recorded, done
        → transient failure              → backoff retry, bounded
        → permanent failure (bad token)  → recorded; token invalidated
        → all attempts exhausted
              ├─ CRITICAL  → FALLBACK CHANNEL, then alert staff   BR-NTF-006
              └─ other     → recorded as failed; visible in admin
```

Delivery receipts vary in fidelity by provider. The model records **what the provider reported** and does not represent "sent" as "read" (ADR-0005).

---

## Ordering and Idempotency

- Handlers are idempotent — a redelivered domain event produces one notification, keyed on `(eventId, recipientId, channel)`.
- Per-recipient ordering is preserved for related events. A "boarded" message must not arrive after "arrived at school".
- Bursts are coalesced where sensible: many students of one guardian boarding the same trip yields one message, not several.

---

## Failure Behaviour

| Failure | Behaviour |
|---|---|
| One provider down | Retry, then fallback channel for `CRITICAL`; others recorded failed |
| All providers down | Queue holds; alert to platform operations; in-app still available |
| Worker down | Queue persists; delivery delayed, not lost |
| Template missing | Fallback chain; gap logged; never blocks dispatch of a `CRITICAL` |
| Recipient has no channel | Recorded; for `CRITICAL`, escalated to staff |

The consistent principle: **a `CRITICAL` notification that cannot reach a parent escalates to a human at the school.** It is never silently dropped.

---

## Verification

1. `CRITICAL` dispatches with all preferences disabled and quiet hours active.
2. `CRITICAL` primary-channel failure escalates to fallback; both attempts recorded.
3. Multi-recipient templates cannot interpolate a student name (BR-NTF-007).
4. Quiet-hours suppression defers and later delivers; nothing is discarded.
5. A redelivered domain event produces exactly one notification per recipient/channel.
6. No domain or application class imports a provider SDK.
7. Every catalog ID has a template in the default locale for each of its channels.
8. Every dispatch attempt writes a delivery record, including failures.
