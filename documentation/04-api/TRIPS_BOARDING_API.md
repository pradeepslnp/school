# TRIPS & BOARDING API 🔴

**Document tier:** 4 — API
**Modules:** MOD-08, MOD-09, MOD-14 · **Features:** TRP-001…008, BRD-001…016, ABS-001…005

**The most safety-critical API surface in the platform.** Every endpoint here is audited; the boarding endpoints are append-only and idempotent by design.

> **Implementation status.** Endpoints marked ✅ are live. Trips (MOD-08) and boarding events with their offline batch (MOD-09) are built; **handover, corrections and reconciliation are not**. [`IMPLEMENTATION_STATUS.md`](../06-development/IMPLEMENTATION_STATUS.md) is the single place that tracks this; the ✅ marks here are a convenience, not a second source of truth.

---

# Trips

| Method | Path | Feature | Permission | Rules | Built |
|---|---|---|---|---|---|
| `GET` | `/trips?schoolId=&serviceDate=` | TRP-004 | `PERM-TRIP-VIEW` | BR-IAM-006, BR-TRACK-002 | ✅ |
| `GET` | `/trips/mine?serviceDate=` | TRP-004 | `PERM-TRIP-VIEW` | BR-IAM-006, BR-TRIP-004 | ✅ |
| `POST` | `/trips/generate?serviceDate=` | TRP-001 | `PERM-ROUTE-MANAGE` | BR-TRIP-011 | ✅ |
| `GET` | `/trips/{id}` | TRP-004 | `PERM-TRIP-VIEW` | | |
| `POST` | `/trips/{id}/start` | TRP-002 | `PERM-TRIP-START` | BR-TRIP-004/005/006 | ✅ |
| `POST` | `/trips/{id}/end` | TRP-004 | `PERM-TRIP-END` | BR-TRIP-002 | ✅ |
| `POST` | `/trips/{id}/close` | TRP-008 | `PERM-TRIP-CLOSE` | BR-TRIP-009, BR-SAFE-001 🔴 | |
| `POST` | `/trips/{id}/cancel` | TRP-005 | `PERM-TRIP-CANCEL` | BR-TRIP-007 | ✅ |
| `GET` | `/trips/{id}/manifest` | TRP-003 | `PERM-TRIP-VIEW` | BR-TRIP-003 | ✅ |
| `POST` | `/trips/{id}/manifest/amendments` | TRP-006 | `PERM-MANIFEST-AMEND` | BR-TRIP-003, BR-AUD-004 | |
| `POST` | `/trips/{id}/staff` | STF-005 | `PERM-DUTY-ASSIGN` | BR-STAFF-006 | |

### Where trips come from

A trip row is **generated ahead of the day it runs** (BR-TRIP-011), not created when a driver taps start. The generator reads the timetable — a route's `operating_days`, its stops' `scheduled_pickup_time` / `scheduled_drop_time`, and the school's calendar exceptions — and writes one `SCHEDULED` trip per route per direction per operating day.

It runs two ways, and they are the same code path:

- **Nightly**, for a rolling horizon (`guardian.trips.generation-horizon-days`, default 3). Covering several days rather than only tomorrow means a night the worker was down repairs itself on the next run instead of leaving a school with no buses.
- **On demand**, via `POST /trips/generate`, for when a timetable is corrected after generation has already run.

Generation is **idempotent at the database**: `uq_trips_route_date_direction` plus `ON CONFLICT DO NOTHING`. That is what lets the job, a manual re-run and a second application instance all run it at once without a distributed lock — and it is why a second call returning `created: 0` is success, not a failure.

It never touches a trip that already exists. A run a transport manager cancelled stays cancelled the next time the job passes over that date.

`POST /trips/generate` is guarded by `PERM-ROUTE-MANAGE` rather than a permission of its own: generation materialises the route timetable and nothing else, so the people entitled to run it are exactly the people entitled to define it. If the permission matrix later separates the two, one annotation changes.

### `POST /trips/{id}/end` and `/close`

`end` moves a trip to `COMPLETED` — the crew has finished driving and no further boarding will be recorded. `close` additionally asserts that **every child on the manifest is accounted for**, which requires trip-close reconciliation (BR-TRIP-009 → BR-SAFE-001 🔴). Reconciliation is MOD-09 and is not built, so `close` **ships with it** rather than as an endpoint that moves a status without doing the check it claims.

### `GET /trips`

Guardian scope returns **only trips carrying one of their children** (BR-TRACK-002). A guardian requesting an arbitrary trip ID receives `403`.

### `GET /trips/mine`

The crew's own runs for a date, and the screen the driver app opens onto. Takes **no identifier** — an endpoint that accepted a staff id could be asked about somebody else's day.

Each run carries its route's code and name, its stop count, and the vehicle the route normally uses:

```json
{ "id": "…", "routeCode": "R3", "routeName": "Green Park", "stopCount": "9",
  "direction": "PICKUP", "status": "SCHEDULED", "scheduledStartTime": "07:15",
  "vehicleId": null,
  "expectedVehicleId": "…", "expectedVehicleDisplayName": "Bus 12",
  "expectedVehicleRegistrationNo": "KA 05 MJ 1234" }
```

`expectedVehicle*` exists for one reason: a `DRIVER` holds no `PERM-VEHICLE-VIEW` (`PERMISSION_MATRIX.md`), so the app cannot list buses for the crew to choose from. It shows the route's usual bus and asks the driver to confirm it against the one in front of them — **confirming is still choosing**, which is what BR-TRIP-004 asks for, and it is why the app's start button reads *"Start · Bus 12 (KA 05 MJ 1234)"* rather than a bare "Start".

It is null when the route has no default vehicle. The app then shows that the run cannot start and says to call the office, instead of offering a start the server would refuse.

**Not yet answerable: "a different bus today."** With no vehicle-list permission and no registration lookup, a crew running a substitute vehicle cannot name it from the handset. Until that is decided, a substitution is a transport manager starting the trip from the console.

`vehicleId` is the bus **actually** running the trip, and stays null until it starts.

### `POST /trips/{id}/start`

```json
{ "vehicleId": "…", "deviceStartedAt": "2026-08-03T07:28:44Z" }
```

`vehicleId` is required — a trip cannot start without naming the bus that is running it, and the vehicle is chosen now rather than at generation because the yard substitutes buses (BR-TRIP-004).

`deviceStartedAt` is the handset's own clock, optional, and **never used in place of server time** (BR-TRIP-008). An offline-first driver app (ADR-0008) may sync hours later, and a phone with a wrong clock must not be able to move a safety record in time.

The crew is **not** named in the body. Who is driving comes from the standing duty roster, and the caller must be on it — or be a transport manager (BR-TRIP-006). A body that named a driver would be a body that could name someone else's. Per-trip crew substitution (`POST /trips/{id}/staff`, BR-STAFF-006) needs a `trip_staff` table that does not exist yet.

Starting also **materialises the manifest** (BR-TRIP-003 🔴): the route's active assignments for this direction, valid on the service date, still enrolled, minus every child with an active absence covering that date and run (BR-ABS-002), with names snapshotted. A start that would produce an **empty** manifest is refused with `TRIP_MANIFEST_EMPTY` — a timetable or assignment mistake is far better caught at 06:30 than at reconciliation.

Runs the full eligibility gate (BR-TRIP-004). **Each failure returns its specific check**, never a generic refusal:

| Failing check | Error | Rule |
|---|---|---|
| Vehicle document expired | `VEHICLE_DOCUMENT_EXPIRED` | BR-FLEET-002 🔴 |
| Driver licence expired | `STAFF_LICENCE_EXPIRED` | BR-STAFF-001 🔴 |
| Licence class wrong for vehicle | `STAFF_LICENCE_CLASS_INVALID` | BR-STAFF-001 🔴 |
| Driver verification lapsed | `STAFF_VERIFICATION_LAPSED` | BR-STAFF-002 🔴 |
| Attendant required, none given | `ATTENDANT_REQUIRED` | BR-STAFF-005 |
| Vehicle already on a trip | `TRIP_VEHICLE_ON_ANOTHER_TRIP` | BR-TRIP-005 |
| Driver already on a trip | `STAFF_ALREADY_ON_ACTIVE_TRIP` | BR-STAFF-004 |

A driver refused at 6:30 AM with "cannot start trip" cannot fix the problem. A driver told "fitness certificate expired 2026-07-15" can call the manager and get another vehicle.

**On success**, the manifest is materialised (BR-TRIP-003 🔴):

```
active route assignments (this route + direction)
  MINUS declared absences (this date + direction)
  WHERE enrolment_status = ACTIVE
       ▼
  trip_manifests, status = EXPECTED — immutable thereafter
```

Response includes the full manifest so the driver app can cache it for offline operation (ADR-0008).

`deviceStartedAt` is stored for reference; `startedAt` is server-recorded and authoritative (BR-TRIP-008).

### `POST /trips/{id}/close` 🔴

**The platform's most important gate.** Refused while any reconciliation item is unresolved:

```json
{
  "error": {
    "code": "TRIP_RECONCILIATION_INCOMPLETE",
    "businessRule": "BR-SAFE-001",
    "details": [
      { "field": "studentId", "issue": "Aarav Sharma boarded at 07:42 with no alight record" }
    ]
  }
}
```

A trip with an unaccounted child **stays visibly open** until a human resolves it with an explicit outcome (BR-TRIP-009, BR-SAFE-001 🔴).

### `POST /trips/{id}/cancel`

`reason` is required (BR-TRIP-007) — it is quoted verbatim to guardians in NTF-TRIP-04. Omitting it returns `422 TRIP_CANCELLATION_REASON_REQUIRED`.

### `POST /trips/{id}/manifest/amendments`

The manifest is immutable (BR-TRIP-003 🔴). Post-start changes are **amendments**, never edits.

```json
{ "studentId": "…", "amendmentType": "REMOVED", "reason": "Parent collected from school gate" }
```

`reason` is required and non-empty (BR-AUD-004) — an unexplained amendment is not evidence. Attempting a direct manifest edit returns `422 TRIP_MANIFEST_IMMUTABLE`.

### `POST /trips/{id}/staff` — mid-trip substitution

Records the outgoing and incoming crew and the handover time (BR-STAFF-006). Both rows remain: after an incident, "who was driving at 3:15 PM" must be answerable.

---

# Boarding 🔴

## `POST /trips/{tripId}/boarding-events` ✅

**Feature:** BRD-001, BRD-002, BRD-003, BRD-004 · **Permission:** `PERM-BOARDING-RECORD`

```json
{
  "clientEventId": "7f3a9c21-4b6e-4d8f-9a1c-2e5b8d4f6a03",
  "studentId": "…",
  "stopId": "…",
  "eventType": "BOARD",
  "verificationMethod": "QR_SCAN",
  "occurredAt": "2026-08-03T07:42:11Z",
  "latitude": 28.5601, "longitude": 77.2065,
  "clockSkewSeconds": -3
}
```

### `clientEventId` is mandatory

It is the idempotency key **and** the database's uniqueness guarantee (BR-BOARD-009). A retry after a timeout returns the original record with `200`, not a duplicate with `201`.

This is not optional. The driver app syncs offline queues by retrying (ADR-0008); without it, a child would be recorded as boarding twice.

### Two timestamps

`occurredAt` is the device clock; the server records `recordedAt` itself. `clockSkewSeconds` is measured at sync. **The device clock is never authoritative** (BR-BOARD-008) — reports order by `occurredAt`, investigations see both.

### Validation

| Condition | Error | Rule |
|---|---|---|
| Not on manifest | `422 BOARDING_STUDENT_NOT_ON_MANIFEST` | BR-BOARD-003 |
| Expected on another active trip | `422 BOARDING_WRONG_VEHICLE` 🔴 | BR-SAFE-003 |
| Already boarded, no alight | `409 BOARDING_ALREADY_BOARDED` | BR-BOARD-005 |
| Alight without board | `422 BOARDING_NOT_BOARDED` | BR-BOARD-006 |
| Alight at a different stop | `422 BOARDING_WRONG_STOP` 🔴 | BR-BOARD-004 |
| Unknown or revoked credential | `422 BOARDING_CREDENTIAL_INVALID` | STU-007 |

`BOARDING_WRONG_VEHICLE` is a safety detection, not a validation nicety: the student is on another trip's manifest for the same date and direction. Both trips' staff and the student's guardians are alerted immediately (NTF-BOARD-07).

### Overrides

```json
{ "clientEventId": "…", "studentId": "…", "eventType": "ALIGHT", "stopId": "…",
  "isOverride": true, "overrideReason": "Parent requested drop at grandmother's stop, confirmed by phone" }
```

`overrideReason` is required and non-empty — enforced by a **database constraint**, not only application code, so no future code path can bypass it (BR-AUD-004).

A wrong-stop override immediately notifies guardians and the transport manager (NTF-BOARD-06, BR-BOARD-004 🔴).

### Immutability

There is **no** `PUT`, `PATCH`, or `DELETE` on boarding events. Any such attempt returns `422 BOARDING_EVENT_IMMUTABLE` (BR-BOARD-001 🔴).

## `POST /trips/{tripId}/boarding-events/{id}/corrections`

**Feature:** BRD-005 · **Permission:** `PERM-BOARDING-CORRECT`

```json
{ "clientEventId": "…", "eventType": "ALIGHT", "stopId": "…",
  "reason": "Scanned wrong student; corrected", "occurredAt": "…" }
```

Creates a **new** record with `correctsEventId` pointing at the original. Both remain visible — a mis-scan and its correction are two facts, and overwriting would destroy the second.

## `POST /trips/{tripId}/boarding-events/batch` ✅

**Feature:** BRD-004 · Offline sync (ADR-0008)

```json
{ "events": [ { "clientEventId": "…", "…": "…" } ] }
```

**`202`** with per-event results. Each event is processed independently — one rejection never discards the batch.

```json
{
  "data": {
    "results": [
      { "clientEventId": "…", "status": "CREATED", "eventId": "…" },
      { "clientEventId": "…", "status": "DUPLICATE", "eventId": "…" },
      { "clientEventId": "…", "status": "FLAGGED_FOR_REVIEW",
        "reason": "Student marked absent after manifest was cached" }
    ]
  }
}
```

**`FLAGGED_FOR_REVIEW`, never rejected** (BR-SAFE-005 🔴). Where a client action contradicts server state, the record is accepted and flagged — losing a real safety record is worse than storing a questionable one.

This inverts the single-event path deliberately, and the inversion is the design. Online, a refusal is useful: the crew is standing in front of the child and can fix it now — scan the right one, tap override, call the office. Offline, the event happened hours ago. The child boarded; refusing the record does not un-board them, it only destroys the evidence that they did. So every conflict here becomes a written row with `sync_state = 'FLAGGED_FOR_REVIEW'`, the refusing error code as its `reason`, and a person's problem.

Each event commits on its own. One conflicting event in a batch of forty never discards the thirty-nine good ones — a stop produces a dozen records in under two minutes, and a busload syncing together is the case this endpoint exists for.

### Device position

`latitude`/`longitude` are stored on the event (V23, BR-BOARD-002) and are **optional**. A handset can have location off, be indoors, or be in a basement car park; refusing to record a child boarding because there is no GPS fix would trade a complete safety record for a precise one. Half a coordinate is refused by a database constraint — a row that looks located and is not is worse than an honestly empty one.

---

# Handover 🔴

## `POST /trips/{tripId}/handovers`

**Feature:** BRD-008, BRD-009 · **Permission:** `PERM-HANDOVER-RECORD` · **Rules:** BR-HAND-001 🔴

```json
{
  "boardingEventId": "…",
  "receivedByGuardianId": "…",
  "verificationMethod": "QR"
}
```

Exactly **one** receiver path: `receivedByGuardianId`, `receivedByPickupPersonId`, `isSelfRelease`, or `isOverride`. Zero or two returns `422` — enforced by a database check constraint.

`boardingEventId` must reference an `ALIGHT` event (BR-HAND-004) → `422 HANDOVER_REQUIRES_ALIGHT_EVENT`.

| Condition | Error | Rule |
|---|---|---|
| Receiver not authorised | `403 HANDOVER_RECEIVER_NOT_AUTHORISED` | BR-HAND-001 🔴 |
| Verification failed | `422 HANDOVER_VERIFICATION_FAILED` | BR-HAND-002 |
| Pickup person outside validity | `422 PICKUP_PERSON_OUTSIDE_VALIDITY` | BR-GRD-005 |
| **Custody restriction** | `403 HANDOVER_REFUSED_CUSTODY_RESTRICTION` 🔴 | BR-HAND-006 |
| Already recorded | `409 HANDOVER_ALREADY_RECORDED` | BR-HAND-004 |

A custody-restricted attempt creates a `HANDOVER_REFUSED` incident and escalates (NTF-HAND-04). **The refusal leaves a trace even though no handover row is created.**

### Override

```json
{ "boardingEventId": "…", "isOverride": true,
  "overrideReason": "Guardian delayed; neighbour known to attendant collected child",
  "unverifiedReceiverName": "Priya Menon", "unverifiedReceiverPhone": "+919812345678" }
```

`unverifiedReceiverName` is **required** — an override recording "unverified adult" and nothing else is not evidence (BR-HAND-003 🔴) → `422 HANDOVER_OVERRIDE_REQUIRES_RECEIVER_IDENTITY`.

Immediately notifies **all** guardians and the transport manager (NTF-HAND-03, `CRITICAL`).

## `POST /trips/{tripId}/handover-exceptions`

**Feature:** BRD-012 · **Rules:** BR-HAND-007 🔴

```json
{ "studentId": "…", "stopId": "…", "exceptionType": "NO_RECEIVER_PRESENT" }
```

**The student remains on the vehicle.** Creates a `NO_RECEIVER` incident, notifies guardians and the transport manager (NTF-HAND-05, `CRITICAL`), and starts the escalation chain (BR-SAFE-006).

The student is **never released to no one.** This is the rule most likely to be argued away for operational convenience, which is why it is 🔴 and why the API has no path that discharges a child without a recorded receiver.

---

# Reconciliation 🔴

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/trips/{id}/reconciliation` | BRD-013 | `PERM-TRIP-VIEW` | BR-SAFE-001 |
| `POST` | `/reconciliation-items/{id}/resolve` | BRD-013 | `PERM-RECONCILIATION-RESOLVE` | BR-SAFE-001 🔴 |

### `GET /trips/{id}/reconciliation`

```json
{
  "data": {
    "status": "EXCEPTIONS",
    "expectedCount": 38, "boardedCount": 36, "alightedCount": 35,
    "items": [
      { "id": "…", "studentId": "…", "studentName": "Aarav Sharma",
        "exceptionType": "UNACCOUNTED", "resolutionOutcome": null }
    ]
  }
}
```

`UNACCOUNTED` — boarded, never alighted — is **the left-behind case this platform exists to catch** (BR-SAFE-001 🔴). It triggers a `CRITICAL` alert to driver, attendant, transport manager, and guardians (NTF-SAFE-01), bypassing all preferences and quiet hours.

### `POST /reconciliation-items/{id}/resolve`

```json
{ "resolutionOutcome": "FOUND_ON_VEHICLE", "resolutionNotes": "Asleep on rear seat; alight recorded 15:47" }
```

Outcomes: `FOUND_ON_VEHICLE` · `RECORD_MISSED` · `NEVER_BOARDED` · `CONFIRMED_NO_SHOW`

Resolution is **all-or-nothing** — outcome, actor, and time together, enforced by a check constraint (`422 RECONCILIATION_RESOLUTION_INCOMPLETE`). There is no way to record what happened without recording who decided it.

`FOUND_ON_VEHICLE` additionally raises a `CRITICAL` incident — a child found on a parked vehicle is a serious event regardless of outcome.

---

# Absence

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/students/{id}/absences` | ABS-001, ABS-002 | `PERM-ABSENCE-DECLARE` | BR-ABS-001/002/003 |
| `GET` | `/students/{id}/absences` | ABS-001 | `PERM-ABSENCE-VIEW` | |
| `DELETE` | `/absences/{id}` | ABS-003 | `PERM-ABSENCE-DECLARE` | BR-ABS-004 |

```json
{ "fromDate": "2026-08-05", "toDate": "2026-08-07", "direction": null, "reason": "Family travel" }
```

`reason` is **optional** — requiring a parent to justify an absence is friction with no safety value.

| Timing | Effect |
|---|---|
| Before trip start | Excluded from materialisation (BR-ABS-002); no-show alerts suppressed (BR-ABS-005) |
| After trip start | `422 ABSENCE_TRIP_ALREADY_STARTED` — use a manifest amendment (BR-ABS-003) |

Cancellation is refused after trip start (BR-ABS-004). A student boarding despite a declared absence raises an alert and records **both** facts (BR-BOARD-007, NTF-BOARD-05).

---

## Verification

1. Trip start refusal names the specific failing check.
2. Manifest is materialised at start and unaffected by later route edits.
3. Replaying a `clientEventId` returns the original record, not a duplicate.
4. `PUT`/`PATCH`/`DELETE` on a boarding event returns `422`.
5. A correction creates a new record; both remain readable.
6. Batch sync processes each event independently; conflicts are flagged, not rejected.
7. A handover with zero or two receiver paths is rejected.
8. A handover override without a receiver identity is rejected.
9. A custody-restricted attempt creates an incident and no handover row.
10. A no-receiver exception leaves the student boarded and escalates.
11. A trip with an unresolved reconciliation item cannot close.
12. Resolving without an outcome, actor, or time is rejected.
