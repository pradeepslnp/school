# MOD-12 — Notification Tables

**Owning module:** `com.guardian.notification` · **Implements:** ADR-0005 · **Rules:** BR-NTF-*

Catalog: [`NOTIFICATION_CATALOG.md`](../../01-product-discovery/NOTIFICATION_CATALOG.md) · Pipeline: [`NOTIFICATION_ARCHITECTURE.md`](../../02-system-design/NOTIFICATION_ARCHITECTURE.md)

---

## `notification_templates`

Templates are **data, not code** (BR-CFG-005, ADR-0007).

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | → `schools`. Null = organization-wide. |
| `catalog_id` | `VARCHAR(32)` | `NOT NULL` — e.g. `NTF-BOARD-01` |
| `channel` | `VARCHAR(16)` | `NOT NULL`, `PUSH` / `SMS` / `EMAIL` / `IN_APP` |
| `locale` | `VARCHAR(16)` | `NOT NULL` |
| `title_template` | `TEXT` | Push and email |
| `body_template` | `TEXT` | `NOT NULL` |
| `provider_template_ref` | `VARCHAR(128)` | Pre-registered ID where the region requires it |
| `version` | `INTEGER` | `NOT NULL DEFAULT 1` |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT uq_notification_templates
    UNIQUE (tenant_id, school_id, catalog_id, channel, locale),
CONSTRAINT ck_notification_templates_channel
    CHECK (channel IN ('PUSH','SMS','EMAIL','IN_APP'))
```

`provider_template_ref` exists because some regions require SMS templates to be pre-registered with the operator before they may be sent (ADR-0007). That registration ID is regional data, not a code concern.

Resolution order (BR-NTF-002): school+locale → org+locale → org+default locale → platform default. Any fallback beyond the first step **logs a template gap** so it can be filled.

**Indexes:** `idx_templates_lookup (tenant_id, catalog_id, channel, locale) WHERE is_active`

---

## `notification_preferences`

| Column | Type | Notes |
|---|---|---|
| `user_id` | `UUID` | `NOT NULL` → `users` |
| `catalog_id` | `VARCHAR(32)` | `NOT NULL` |
| `channel` | `VARCHAR(16)` | `NOT NULL` |
| `is_enabled` | `BOOLEAN` | `NOT NULL DEFAULT true` |
| `quiet_hours_start`, `quiet_hours_end` | `TIME` | School time zone |

```sql
CONSTRAINT uq_notification_preferences UNIQUE (tenant_id, user_id, catalog_id, channel)
```

**These rows have no effect on `CRITICAL` notifications** (BR-NTF-006 🔴). The suppression check is skipped entirely for that class — it is not that preferences are consulted and overridden, but that they are never read.

This is deliberate: a parent can safely mute everything else *because* the events that matter always arrive ([`NOTIFICATION_CATALOG.md`](../../01-product-discovery/NOTIFICATION_CATALOG.md)).

Absent rows mean "use the catalog default" — the table stores deviations, not every combination.

---

## `notifications`

One row per notification event occurrence — **not per recipient**.

| Column | Type | Notes |
|---|---|---|
| `catalog_id` | `VARCHAR(32)` | `NOT NULL` |
| `priority_class` | `VARCHAR(16)` | `NOT NULL`, `CRITICAL` / `URGENT` / `STANDARD` / `INFO` |
| `subject_student_id` | `UUID` | → `students` |
| `trip_id` | `UUID` | → `trips` |
| `source_event_id` | `UUID` | `NOT NULL` — domain event; idempotency key |
| `payload` | `JSONB` | `NOT NULL` — template variables |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |

```sql
CONSTRAINT uq_notifications_source_event UNIQUE (tenant_id, source_event_id, catalog_id),
CONSTRAINT ck_notifications_priority CHECK (
    priority_class IN ('CRITICAL','URGENT','STANDARD','INFO'))
```

**`uq_notifications_source_event` is the idempotency guarantee.** Domain events may be redelivered — a worker restart, a retry. Without this constraint, a redelivered `StudentBoarded` event would send a second "Aarav boarded" message. The unique constraint makes the duplicate insert fail, and the handler treats that as success.

---

## `notification_deliveries`

**One row per attempt**, per recipient, per channel. This is the table that answers *"why was I not told?"* — a question that will be asked after an incident.

| Column | Type | Notes |
|---|---|---|
| `notification_id` | `UUID` | `NOT NULL` → `notifications` |
| `recipient_user_id` | `UUID` | `NOT NULL` → `users` |
| `channel` | `VARCHAR(16)` | `NOT NULL` |
| `destination` | `VARCHAR(255)` | Masked phone or email; never the full value in logs |
| `attempt_no` | `INTEGER` | `NOT NULL DEFAULT 1` |
| `status` | `VARCHAR(24)` | `NOT NULL`, `PENDING` / `SENT` / `DELIVERED` / `FAILED` / `SUPPRESSED` |
| `provider_reference` | `VARCHAR(255)` | |
| `failure_reason` | `TEXT` | |
| `is_fallback` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `sent_at`, `delivered_at` | `TIMESTAMPTZ` | |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |

```sql
CONSTRAINT ck_deliveries_status CHECK (
    status IN ('PENDING','SENT','DELIVERED','FAILED','SUPPRESSED')),
CONSTRAINT ck_deliveries_failure CHECK (status <> 'FAILED' OR failure_reason IS NOT NULL)
```

### Why attempts are rows, not a counter

A counter tells you a notification failed three times. Rows tell you *which channel failed, when, with what provider error, and whether the fallback succeeded*. After a safety incident, the difference between those two is the difference between an answer and a shrug (BR-NTF-005).

**`SUPPRESSED` is distinct from `FAILED`.** A quiet-hours suppression (BR-NTF-004) is recorded so the deferred delivery is traceable — suppression defers, it never discards.

**`is_fallback`** marks escalation after primary-channel failure for `CRITICAL` (BR-NTF-006), so the escalation path is auditable.

**Indexes**
```sql
idx_deliveries_pending (tenant_id, status) WHERE status = 'PENDING'
idx_deliveries_notification (tenant_id, notification_id)
idx_deliveries_recipient (tenant_id, recipient_user_id, created_at DESC)
```

The last index serves the in-app notification centre (NTF-006) — the durable record a parent scrolls back through.

---

## Multi-Recipient Safety

BR-NTF-007 🔴 — a notification sent to more than one family may not name any child.

`notifications.payload` carries template variables. For catalog entries flagged multi-recipient (NTF-INC-04, NTF-TRIP-04), the rendering layer rejects any template referencing a student-name variable.

Enforced in code and covered by a test asserting multi-recipient templates cannot interpolate student names — **not enforceable as a database constraint**, and documented as such.

---

## Verification

1. A redelivered domain event produces exactly one notification row.
2. Every dispatch attempt writes a delivery row, including failures and suppressions.
3. A `FAILED` delivery without a reason is rejected.
4. `CRITICAL` dispatches with preferences disabled and quiet hours active.
5. `CRITICAL` primary-channel failure produces a fallback row with `is_fallback = true`.
6. A quiet-hours suppression is later delivered, not dropped.
7. Multi-recipient templates cannot reference a student name.
8. Every catalog ID has a template in the default locale for each of its channels.
