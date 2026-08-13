# TRACKING, ALERTS, NOTIFICATION & INCIDENT API

**Document tier:** 4 — API
**Modules:** MOD-10 … MOD-13 · **Features:** TRK-001…008, ALT-001…007, NTF-001…009, INC-001…007

---

# Tracking

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/ingestion/positions` | TRK-001 | device credential | BR-TRACK-004, BR-FLEET-006 |
| `GET` | `/trips/{id}/position` | TRK-003 | `PERM-TRACKING-LIVE-VIEW` | BR-TRACK-001/002/003 |
| `GET` | `/schools/{id}/live-map` | TRK-004 | `PERM-TRACKING-LIVE-VIEW` | BR-TRACK-001 |
| `GET` | `/trips/{id}/eta` | TRK-005 | `PERM-TRACKING-LIVE-VIEW` | BR-TRACK-006 |
| `GET` | `/trips/{id}/position-history` | TRK-006 | `PERM-TRACKING-HISTORY-VIEW` | BR-TRACK-007 |

## `POST /ingestion/positions`

**Device credential path only** — never a human token (ADR-0006).

```json
{ "reports": [ { "deviceIdentifier": "…", "latitude": 28.5601, "longitude": 77.2065,
  "speedMps": 8.3, "headingDeg": 145, "ignitionOn": true, "accuracyM": 4.2,
  "deviceTime": "2026-08-03T07:42:11Z" } ] }
```

Batched, since devices buffer through coverage gaps. Validation rejects implausible reports — coordinate range, speed, implied speed between fixes, timestamp sanity, accuracy floor (BR-TRACK-004). **Rejected reports are logged and dropped, never stored as fact.**

An unregistered device is logged and ignored, never auto-registered (BR-FLEET-006) — otherwise anyone could inject positions for a vehicle they do not own.

Acknowledgement budget: p95 < 100 ms ([`REALTIME_TRACKING_DESIGN.md`](../02-system-design/REALTIME_TRACKING_DESIGN.md)).

## `GET /trips/{id}/position`

```json
{
  "data": {
    "latitude": 28.5601, "longitude": 77.2065, "speedMps": 8.3, "headingDeg": 145,
    "deviceTime": "2026-08-03T07:42:11Z", "receivedAt": "2026-08-03T07:42:13Z",
    "isStale": false, "staleSinceSeconds": 2
  }
}
```

Served from Redis; never touches PostgreSQL. **`isStale` is always present** (BR-TRACK-003) — a stale position must never be displayed as current.

Available **only while the trip is active** (BR-TRACK-001) → `422 TRACKING_NOT_AVAILABLE_OUTSIDE_TRIP`. Vehicles are not tracked outside trip windows; this is what keeps the platform a safety tool rather than staff surveillance.

Guardians see only trips carrying one of their children (BR-TRACK-002) → `403`.

## `GET /trips/{id}/eta`

```json
{ "data": { "stops": [ { "stopId": "…", "estimatedArrival": "2026-08-03T07:46:00Z",
  "calculatedAt": "2026-08-03T07:42:13Z", "confidence": "HIGH" } ] } }
```

**`calculatedAt` and `confidence` are always returned** (BR-TRACK-006). An ETA is an estimate; a parent who leaves the house on a stale one and misses the bus is a product failure. `confidence` drops to `LOW` when routing is unavailable and straight-line fallback is used.

## WebSocket

```
/topic/trip/{tripId}/position
/topic/trip/{tripId}/eta
/topic/school/{schoolId}/alerts
/user/queue/notifications
```

**Authorisation is checked at subscribe time, per topic** → `403 TRACKING_SUBSCRIPTION_DENIED`. An unchecked subscription would expose any vehicle's live position to anyone who could guess a trip ID.

Subscriptions close when the trip reaches `COMPLETED`.

---

# Alerts

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/alerts` | ALT-007 | `PERM-ALERT-VIEW` | BR-ALERT-005/006 |
| `POST` | `/alerts/{id}/acknowledge` | ALT-007 | `PERM-ALERT-RESOLVE` | BR-ALERT-006 |
| `POST` | `/alerts/{id}/resolve` | ALT-007 | `PERM-ALERT-RESOLVE` | BR-ALERT-006 |
| `GET`/`PUT` | `/schools/{id}/alert-rules` | ALT-004…006 | `PERM-CONFIG-EDIT` | BR-CFG-003 🔴 |

`GET /alerts?status=OPEN&sort=-severity` — the transport manager's dashboard query.

A continuing condition holds **one** open alert with an advancing `lastObservedAt`, not a stream (BR-ALERT-005). A bus deviating for twenty minutes is one alert, observed repeatedly.

`POST /alerts/{id}/resolve` requires `resolutionOutcome` (BR-ALERT-006) → `422 ALERT_RESOLUTION_OUTCOME_REQUIRED`. Alerts are never silently dropped; closing one means someone decided something.

### Alert rules

```json
{ "rules": [ { "ruleType": "OVERSPEED", "thresholdValue": 16.7, "durationSeconds": 30,
  "severity": "HIGH", "isEnabled": true } ] }
```

**Every threshold has both a magnitude and a duration.** An instantaneous speed spike from a bad GPS fix is not overspeed. Without the duration dimension managers receive constant false alerts and stop reading them — which makes the real one invisible.

Values outside platform floors return `422 CONFIG_VALUE_OUT_OF_BOUNDS` (BR-CFG-003 🔴). A tenant may tighten a safety threshold; never loosen it past the floor (BR-SAFE-007 🔴).

---

# Notifications

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/notifications/me` | NTF-006 | authenticated | BR-NTF-007 |
| `POST` | `/notifications/{id}/read` | NTF-006 | authenticated | |
| `GET`/`PUT` | `/users/me/notification-preferences` | NTF-007 | `PERM-NOTIFICATION-PREFERENCE-SELF` | BR-NTF-003/006 |
| `GET`/`PUT` | `/notification-templates` | NTF-002 | `PERM-NOTIFICATION-TEMPLATE-MANAGE` | BR-NTF-002 |
| `GET` | `/notifications/{id}/deliveries` | NTF-009 | `PERM-NOTIFICATION-DELIVERY-VIEW` | BR-NTF-005 |

### `PUT /users/me/notification-preferences`

```json
{ "preferences": [ { "catalogId": "NTF-TRIP-01", "channel": "PUSH", "isEnabled": false } ],
  "quietHoursStart": "21:00", "quietHoursEnd": "06:00" }
```

Attempting to disable a `CRITICAL` notification returns `422 NOTIFICATION_PREFERENCE_NOT_APPLICABLE` (BR-NTF-006 🔴).

This refusal is the point: a parent can safely mute routine notifications **because** the events that matter always arrive. Quiet hours **defer** standard notifications; they never discard them (BR-NTF-004).

### `GET /notifications/{id}/deliveries`

One row **per attempt** — channel, provider reference, status, failure reason, whether it was a fallback.

This is the endpoint that answers *"why was I not told?"* after an incident (BR-NTF-005). A counter would say a notification failed three times; these rows say which channel failed, when, with what error, and whether the fallback succeeded.

---

# Incidents & SOS 🔴

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/sos` | INC-001 | `PERM-SOS-RAISE` | BR-INC-001/002, BR-SAFE-004 🔴 |
| `POST` | `/sos/{id}/acknowledge` | INC-003 | `PERM-SOS-ACKNOWLEDGE` | BR-SAFE-006 |
| `POST` | `/sos/{id}/resolve` | INC-003 | `PERM-SOS-ACKNOWLEDGE` | BR-INC-005/006 |
| `POST` | `/incidents` | INC-004 | `PERM-INCIDENT-CREATE` | BR-INC-003 |
| `GET` | `/incidents` | INC-005 | `PERM-INCIDENT-VIEW` | BR-INC-004, BR-NTF-007 |
| `POST` | `/incidents/{id}/resolve` | INC-006 | `PERM-INCIDENT-RESOLVE` | BR-INC-005 |

## `POST /sos` 🔴

```json
{ "tripId": "…", "latitude": 28.5601, "longitude": 77.2065, "source": "DRIVER_APP" }
```

**The highest-priority operation in the platform.** Minimal payload by design — it is raised one-handed, possibly in an emergency, from any screen in the driver app.

Dispatched immediately, **bypassing every preference, quiet hour, and channel opt-out** (BR-SAFE-004 🔴). The escalation chain runs until acknowledged (BR-SAFE-006 🔴):

```
L1 Transport Manager  ──unacknowledged──► L2 School Admin + Principal
                                       ──unacknowledged──► L3 Emergency contacts
```

## `POST /sos/{id}/resolve`

```json
{ "resolutionOutcome": "FALSE_ALARM", "resolutionNotes": "Button pressed accidentally" }
```

**An SOS is never deleted** → `422 SOS_CANNOT_BE_DELETED` (BR-INC-006 🔴). `FALSE_ALARM` is a resolution outcome, not a delete.

This matters: a driver whose SOS fires accidentally every week is a pattern worth seeing — a faulty device, or a button catching a sleeve. Deleting false alarms erases exactly the data that reveals the problem.

## Incidents

```json
{ "tripId": "…", "studentId": "…", "incidentType": "MEDICAL",
  "severity": "HIGH", "description": "…", "occurredAt": "…" }
```

**Notification audience follows severity and scope** (BR-INC-004):

| Scope | Audience | Constraint |
|---|---|---|
| Student-specific | That child's guardians | May name the child |
| Trip-wide | All guardians on the manifest | **Must name no child** (BR-NTF-007 🔴) |

`GET /incidents` for a guardian returns only incidents affecting their own child.

Resolution requires an outcome, actor, and time (BR-INC-005) → `422 INCIDENT_RESOLUTION_REQUIRED`.

---

## Verification

1. An implausible position report is rejected and logged, not stored.
2. An unregistered device's report is ignored, not auto-registered.
3. Live position is unavailable outside an active trip.
4. A guardian cannot read position for a trip not carrying their child.
5. A WebSocket subscribe without permission is refused.
6. Live position responses always carry `isStale`; ETAs always carry `calculatedAt` and `confidence`.
7. A continuing deviation yields one alert with an advancing `lastObservedAt`.
8. An alert rule below the platform floor is rejected.
9. Disabling a `CRITICAL` notification preference is refused.
10. `CRITICAL` dispatches with preferences off and quiet hours active; failures produce a fallback delivery row.
11. An SOS cannot be deleted; unacknowledged SOS escalates a level.
12. A trip-wide incident notification names no student.
