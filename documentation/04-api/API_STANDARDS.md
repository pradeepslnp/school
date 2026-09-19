# API STANDARDS

**Document tier:** 4 — API
**Status:** Active

Binding on every endpoint. Deviations require an ADR.

---

## Base

```
https://api.guardianplatform.io/api/v1
```

Versioning in the path. `v1` is stable: no breaking change without `v2`. Additive changes — new optional fields, new endpoints — are not breaking and ship within `v1`.

All requests and responses are `application/json; charset=utf-8`. TLS 1.2+ everywhere, including device ingestion.

---

## Resource Naming

| Rule | Example |
|---|---|
| Plural nouns | `/students`, `/trips` |
| Kebab-case multi-word | `/boarding-events`, `/authorised-pickup-persons` |
| Nesting only for ownership | `/routes/{routeId}/stops` |
| Max two levels of nesting | `/trips/{tripId}/boarding-events` |
| Actions as sub-resources, not verbs | `POST /trips/{tripId}/start` |

Verbs in paths are permitted **only** for state transitions that are not CRUD: `start`, `end`, `close`, `cancel`, `acknowledge`, `resolve`, `revoke`. `discard` is the one hard removal, for a record entered by mistake with no safety history, and is a `POST` action precisely so that `DELETE` keeps meaning "soft" ([ADR-0019](../00-governance/adr/ADR-0019-discarding-mistaken-entries-and-phone-correction.md)). `POST /trips/{id}/start` is clearer and safer than `PATCH /trips/{id}` with a status field, because it makes the transition explicit and separately permissionable.

---

## Methods

| Method | Use | Idempotent |
|---|---|---|
| `GET` | Read | Yes |
| `POST` | Create, or a state transition | No — unless an idempotency key is supplied |
| `PUT` | Full replace | Yes |
| `PATCH` | Partial update | No |
| `DELETE` | Deactivate (soft) | Yes |

**`DELETE` never hard-deletes.** It sets `is_active = false`. Safety and audit records have no `DELETE` endpoint at all ([`CONVENTIONS.md`](../03-database/CONVENTIONS.md)).

---

## Standard Response Envelope

### Single resource

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "student",
    "attributes": { }
  },
  "meta": { "requestId": "…", "timestamp": "2026-08-03T07:42:11Z" }
}
```

### Collection

```json
{
  "data": [ ],
  "meta": {
    "requestId": "…",
    "timestamp": "2026-08-03T07:42:11Z",
    "pagination": {
      "cursor": "eyJpZCI6…",
      "nextCursor": "eyJpZCI6…",
      "limit": 50,
      "hasMore": true
    }
  }
}
```

### Error

```json
{
  "error": {
    "code": "TRIP_VEHICLE_DOCUMENT_EXPIRED",
    "messageKey": "error.trip.vehicle_document_expired",
    "message": "Vehicle document has expired and the trip cannot start.",
    "details": [
      { "field": "vehicleId", "issue": "Fitness certificate expired on 2026-07-15" }
    ],
    "businessRule": "BR-FLEET-002",
    "requestId": "…",
    "timestamp": "2026-08-03T07:42:11Z"
  }
}
```

**`businessRule` is deliberate.** When an operation is refused by a rule, the response names the rule. A driver refused at 6:30 AM needs to know *which* check failed ([`MOD-05-06-fleet-staff.md`](../03-database/tables/MOD-05-06-fleet-staff.md)), and a support engineer needs to find the rule without reading source.

**`messageKey` is the localised resource key** (BR-CFG-005). `message` is a fallback in the tenant's default locale, never the authority for display.

Full list: [`ERROR_CATALOG.md`](ERROR_CATALOG.md).

---

## Field Conventions

| Concern | Rule |
|---|---|
| Case | `camelCase` in JSON, `snake_case` in the database ([`GLOSSARY.md`](../00-governance/GLOSSARY.md)) |
| Identifiers | UUID strings |
| Timestamps | ISO 8601 UTC with `Z` — `2026-08-03T07:42:11Z` |
| Dates | `YYYY-MM-DD` |
| Times of day | `HH:mm` — school-local, always with the school's timezone in context |
| Enums | `SCREAMING_SNAKE_CASE` |
| Money | String decimal, never float |
| Distance, speed | SI — metres, m/s. Converted at display, never in transit. |
| Absent values | Omit the field or send `null`; never send `""` or `0` as "unknown" |

**All timestamps are UTC on the wire.** Clients render in the school's timezone (BR-CFG-006). A local time on the wire without a zone is the commonest source of off-by-hours bugs in a multi-region platform.

---

## Pagination

**Cursor-based**, not offset.

```
GET /students?limit=50&cursor=eyJpZCI6…
```

Offset pagination skips or repeats rows when the underlying set changes between pages — unacceptable when the caller is exporting a student register. Cursors are opaque, encode the sort key, and are stable.

Default `limit` 50, maximum 200.

---

## Filtering and Sorting

```
GET /trips?schoolId=…&serviceDate=2026-08-03&status=IN_PROGRESS&sort=-startedAt
```

Filters are explicit query parameters — no generic query language. `sort` takes a field name, `-` prefix for descending. Only documented sortable fields are accepted; an undocumented one returns `400`, never an unindexed scan.

---

## Idempotency

Required for `POST` endpoints that create safety records.

```
Idempotency-Key: 7f3a9c21-4b6e-4d8f-9a1c-2e5b8d4f6a03
```

For boarding events the key is `clientEventId` in the body, which is also the database's uniqueness guarantee (BR-BOARD-009, ADR-0008). A retry after a timeout returns the original result with `200`, not a duplicate record with `201`.

**This is not optional for the driver app.** Offline sync retries by design; without idempotency a child would be recorded as boarding twice.

---

## Authentication

```
Authorization: Bearer <access token>
```

15-minute access tokens, rotating single-use refresh tokens (ADR-0006). See [`AUTHENTICATION_API.md`](AUTHENTICATION_API.md).

Every endpoint declares a permission from [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md). An endpoint without one is unreachable (BR-IAM-002) and fails an architecture test.

### `403` vs `404`

An authenticated user requesting a resource outside their scope receives **`403`**, not `404`.

Returning `404` to hide existence is a common pattern, but here the tenant boundary is already enforced by RLS — cross-tenant resources are genuinely invisible and genuinely return `404`. Within a tenant, `403` is the honest answer and avoids a probing oracle where `404` would mean two different things.

---

## Rate Limiting

Per user, per IP, per tenant. Stricter on authentication and OTP. Ingestion limited per device.

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 987
X-RateLimit-Reset: 1754208000
Retry-After: 30          (on 429)
```

---

## Status Codes

| Code | Use |
|---|---|
| `200` | Success |
| `201` | Created — `Location` header set |
| `202` | Accepted — queued (bulk import, export) |
| `204` | Success, no body |
| `400` | Malformed or invalid input |
| `401` | Missing or invalid credentials |
| `403` | Authenticated but not permitted, or out of scope |
| `404` | Not found, or not visible at all |
| `409` | Conflict — duplicate, or invalid state transition |
| `422` | Well-formed but violates a business rule — **`businessRule` is set** |
| `429` | Rate limited |
| `500` | Server error — never leaks internal detail |
| `503` | Dependency unavailable |

**`400` vs `422` matters here.** `400` means the request was malformed. `422` means it was understood and refused by a business rule — a trip that cannot start because a document expired is `422` with `businessRule: "BR-FLEET-002"`.

---

## Validation

Validated at the boundary; a client-supplied identifier is never trusted. All fields in `details[]` on failure, not just the first — a bulk form should not require six round trips.

---

## WebSocket

```
wss://api.guardianplatform.io/ws
```

STOMP over WebSocket. JWT at connect. **Subscription authorisation is checked at subscribe time, per topic** — see [`REALTIME_TRACKING_DESIGN.md`](../02-system-design/REALTIME_TRACKING_DESIGN.md).

```
/topic/trip/{tripId}/position
/topic/trip/{tripId}/eta
/topic/school/{schoolId}/alerts
/user/queue/notifications
```

Subscriptions close when a trip reaches `COMPLETED` (BR-TRACK-001).

---

## Documentation

Every endpoint is documented with: its feature ID, its permission, the business rules it enforces, request and response schemas, and error cases.

OpenAPI 3.1 is generated from annotations and validated in CI against the documented contract — the specification cannot drift from the implementation without failing the build.

---

## Verification

1. Every endpoint declares a permission that exists in the permission matrix.
2. Every endpoint references a feature ID from [`FEATURE_INVENTORY.md`](../01-product-discovery/FEATURE_INVENTORY.md).
3. Every error response conforms to the envelope and its code exists in the error catalog.
4. Idempotent replay of a boarding event returns the original record, not a duplicate.
5. Cross-scope requests return `403`; cross-tenant return `404`.
6. All timestamps in responses are UTC with `Z`.
7. Undocumented sort fields return `400`.
8. Generated OpenAPI matches the documented contract.
