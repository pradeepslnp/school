# STUDENTS & GUARDIANS API

**Document tier:** 4 — API
**Modules:** MOD-03, MOD-04 · **Features:** STU-001…008, GRD-001…007

These endpoints govern **who may collect a child**. Every write here is audited.

---

## Students

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/students` | STU-001 | `PERM-STUDENT-CREATE` | BR-STU-001, BR-STU-003 |
| `GET` | `/students` | STU-001 | `PERM-STUDENT-VIEW` | BR-IAM-005, BR-IAM-012 |
| `GET` | `/students/{id}` | STU-001 | `PERM-STUDENT-VIEW` | BR-IAM-005, BR-IAM-012 |
| `PATCH` | `/students/{id}` | STU-001 | `PERM-STUDENT-EDIT` | |
| `POST` | `/students/{id}/withdraw` | STU-004 | `PERM-STUDENT-EDIT` | BR-STU-005 |
| `POST` | `/students/{id}/discard` | STU-008 | `PERM-STUDENT-DELETE` | BR-STU-007 |
| `GET` | `/students/{id}/transport` | STU-009 | `PERM-STUDENT-VIEW` | BR-IAM-006, BR-IAM-012 |
| `GET` | `/students/{id}/journey` | STU-009 | `PERM-STUDENT-VIEW` | BR-IAM-006, BR-IAM-012, BR-TRACK-001 — **planned** |
| `POST` | `/students/import` | STU-002 | `PERM-STUDENT-IMPORT` | BR-STU-003 |
| `GET` | `/students/import/{jobId}` | STU-002 | `PERM-STUDENT-IMPORT` | |
| `GET` | `/students/import/{jobId}/errors.csv` | STU-002 | `PERM-STUDENT-IMPORT` | BR-RPT-002 🔴 |
| `POST` | `/students/{id}/transfer` | STU-005 | `PERM-STUDENT-EDIT` | BR-STU-006 |
| `PUT` | `/students/{id}/photo` | STU-006 | `PERM-STUDENT-EDIT` | |
| `GET` | `/students/{id}/photo` | STU-006 | `PERM-STUDENT-VIEW` | BR-IAM-012 |
| `POST` | `/students/{id}/credentials` | STU-007 | `PERM-STUDENT-EDIT` | |
| `DELETE` | `/students/{id}/credentials/{credId}` | STU-007 | `PERM-STUDENT-EDIT` | |

### Scope narrowing

`GET /students` returns radically different sets by role:

| Role | Sees |
|---|---|
| `SCHOOL_ADMIN` | All students in scope schools |
| `TRANSPORT_MANAGER` | All students in scope schools |
| `DRIVER` / `ATTENDANT` | **Current trip manifest only** |
| `GUARDIAN` | **Own children only** (BR-IAM-005) |

Requesting a student outside scope returns `403 AUTH_SCOPE_DENIED` — object-level authorisation, not just endpoint-level.

**Every non-guardian read writes a data-access record** (BR-IAM-012 🔴).

### `GET /students/{id}/photo`

Photos are served through this authorising endpoint, never as a public URL — `photo_ref` is a storage key, not a link. A guessable photo URL for a child is a safety problem ([`MOD-03-04-students-guardians.md`](../03-database/tables/MOD-03-04-students-guardians.md)).

### `POST /students/import`

`multipart/form-data` with two parts: `schoolId` (the school every row enrols into — a student
belongs to one school, BR-STU-001) and `file` (the spreadsheet, exported as CSV). Returns `202`
with a job.

```json
{
  "data": {
    "jobId": "…", "status": "COMPLETED",
    "totalRows": 412, "successCount": 408, "errorCount": 4,
    "errors": [
      { "row": 17, "field": "admissionNo", "code": "STUDENT_ADMISSION_NO_EXISTS",
        "message": "Admission number GW-2024-0117 already exists in this school" }
    ],
    "errorReportUrl": "/students/import/{jobId}/errors.csv"
  }
}
```

**Columns.** The header is matched case-insensitively, ignoring spaces and underscores.
Recognised: `admissionNo`, `firstName`, `lastName` (all required), `dateOfBirth`
(`YYYY-MM-DD`, optional), `transportEligible` (`true`/`false`/`yes`/`no`/`1`/`0`, optional,
defaults `true`). **An unrecognised column stops the whole file** with
`STUDENT_IMPORT_UNSUPPORTED_COLUMN` — enrolling students while silently dropping a `guardian`
or `stop` column the office believed it was providing is the more dangerous outcome. Guardian
links and route assignment in the same upload are a documented follow-up, not in this version.

**Per-row validation; valid rows are imported.** The file is never rejected wholesale for a bad
row — Fatima imports several hundred students per term from spreadsheets of varying quality, and
a single bad row must not discard 411 good ones ([`PERSONAS.md`](../01-product-discovery/PERSONAS.md)).
It *is* rejected before any row is processed when it cannot be read at all — empty, binary, an
unknown column, or above the synchronous row cap (5,000). Processing is synchronous; the job
shape is kept so a later move to a background worker does not change the contract.

`status` is `COMPLETED` for any file that was processed. Every enrolled student writes its own
`STUDENT_CREATED` audit record, exactly as the single-student endpoint does, plus one
`STUDENT_IMPORT_COMPLETED` record for the run.

### `GET /students/import/{jobId}/errors.csv`

The failed rows as `text/csv` (`row,field,code,message`), for the office to fix and re-upload.
A data export of child identifiers, so it is audited with a record count (BR-RPT-002 🔴).

### `POST /students/{id}/withdraw`

Sets `enrolmentStatus` and removes future route assignments. **Never hard-deletes** while safety records reference the student (BR-STU-005). A record entered by mistake is discarded instead (below).

### `POST /students/{id}/discard`

Permanently removes a student record **entered by mistake** — a duplicate, or one with the wrong admission number (STU-008, BR-STU-007, [ADR-0019](../00-governance/adr/ADR-0019-discarding-mistaken-entries-and-phone-correction.md)). A named action rather than `DELETE`: `DELETE` never hard-deletes on this platform, and a `POST` is not retried.

```json
{ "reason": "Duplicate of admission 2024-118, entered twice during import" }
```

- `reason` is required, 1–500 characters.
- In one transaction: the student's guardian links, route assignments, and boarding credentials are removed, then the student.
- **Any other reference refuses the discard** — boarding, manifest, absence, notification, handover code, custody restriction, pickup nomination — with `422 STUDENT_HAS_SAFETY_RECORDS`, and nothing changes. Withdraw such a student instead.
- Guardian records are kept; they may belong to a sibling.
- A school-scoped caller may discard only within their school; any other student answers `404 STUDENT_NOT_FOUND`.
- Audited as `STUDENT_DISCARDED` with the reason, admission number, school, and counts removed — never the child's name.
- Answers `204 No Content`.

### Student transport and journey

Served by **MOD-18**, not MOD-03: the composition spans routes, fleet and staff (and later trips, boarding and tracking), which all sit above the student module ([ADR-0020](../00-governance/adr/ADR-0020-staff-student-journey-reads.md)). Both reads are scoped to the caller's schools inside the query. Out of scope and not found are the same `404 STUDENT_NOT_FOUND`. Each read is recorded as data access (BR-IAM-012).

#### `GET /students/{id}/transport`

**Status: implemented.** The bus and crew the student is **assigned** to, per direction. This is the plan, never the child's location: a running trip may use a substitute bus or crew, and only boarding records say where a child is.

```json
{
  "studentId": "…", "schoolId": "…",
  "legs": [
    {
      "direction": "PICKUP",
      "routeId": "…", "routeCode": "R-12", "routeName": "Green Park corridor",
      "stopId": "…", "stopName": "Green Park",
      "vehicle": { "id": "…", "registrationNo": "DL1PC1234", "displayName": "Bus 12", "status": "ACTIVE" },
      "crew": [ { "staffId": "…", "role": "DRIVER", "firstName": "Suresh", "lastName": "Kumar" } ]
    }
  ]
}
```

- One leg per **active** route assignment, pickup first — the same assignments `GET /students/{id}/route-assignments` returns.
- `vehicle` is the route's default bus, or `null` when none is set. A `status` other than `ACTIVE` means the route points at a bus not in service.
- `crew` is every active driver and attendant whose duty on that route covers this direction (or both) and is in effect **today in the school's timezone**. It is empty when nobody is on duty. Names only; phones stay on the Drivers screen.
- No legs when the student has no route assignment.

#### `GET /students/{id}/journey`

**Status: planned.** Needs MOD-08 Trips and MOD-09 Boarding; the bus position also needs MOD-10 Tracking. It will return:
- **now:** the child's journey state (reusing the parent app's `JourneyState`), today's trip and bus, and the bus position while the child is on board (BR-TRACK-001)
- **today:** every boarding, arrival and handover event with its time, stop, recording staff member and verification method
- **history:** the same timeline for a chosen past date, absences included

### Credentials

`POST /students/{id}/credentials` issues a QR or card credential (STU-007). The raw value is returned **once, in this response only** — it is stored hashed and can never be retrieved again. A leaked credential table would let anyone forge a boarding scan.

---

## Guardians

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/guardians` | GRD-001 | `PERM-GUARDIAN-MANAGE` | |
| `GET` | `/guardians/{id}` | GRD-001 | `PERM-GUARDIAN-MANAGE` | |
| `PATCH` | `/guardians/{id}` | GRD-001 | `PERM-GUARDIAN-MANAGE` | BR-IAM-014 |
| `POST` | `/guardians/{id}/invite` | GRD-001 | `PERM-GUARDIAN-MANAGE` | |
| `GET` | `/guardians/me/students` | GRD-007 | authenticated | BR-IAM-005 |

A guardian record exists — receiving SMS, authorised for handover — **before any account is activated**. Requiring an app account first would exclude exactly the parents the platform must reach ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §6).

### `PATCH /guardians/{id}`

**Status: implemented.** Corrects a guardian's name, phone, or email.

```json
{ "firstName": "Anita", "lastName": "Rao", "phone": "+919876543210", "email": "anita@example.com" }
```

**Changing the phone moves the guardian's sign-in to the new number** (BR-IAM-014, [ADR-0019](../00-governance/adr/ADR-0019-discarding-mistaken-entries-and-phone-correction.md)):

1. The new number's sign-in account is reused if one exists in the organization, or created, and granted `GUARDIAN`.
2. The guardian record is relinked to it.
3. The old number's account loses `GUARDIAN` and **every session it holds, immediately**. With no role left it becomes `INACTIVE`. It is never deleted.

The old account is not edited in place: anything done under it stays attributed to the number that did it.

- Every field is sent; a missing name or phone is `400`. An empty or absent `email` clears it.
- Answers `200` with the guardian record: `{ "id", "firstName", "lastName", "phone", "email", "hasLogin" }`. The console re-reads `GET /students/{studentId}/guardians` afterwards, since that is where the rights on each link live.
- A new number whose account already belongs to a different guardian record answers `409 GUARDIAN_PHONE_IN_USE`.
- An unknown guardian answers `404 GUARDIAN_NOT_FOUND`.
- Audited as `GUARDIAN_UPDATED` with the fields changed and whether the sign-in moved — never the values.

### `GET /guardians/me/students`

**Status: implemented.** Served by **MOD-18 `com.guardian.parent`**, not by MOD-04 — the review this endpoint was waiting on found that MOD-04 cannot reach trip state without a module dependency cycle. See [`ADR-0010`](../00-governance/adr/ADR-0010-parent-read-composition.md) for the decision and its accepted cost.

This is the parent app's primary read. P-02 must answer "is my child fine?" with **zero taps**, so the endpoint returns each child's current journey state inline rather than making the client compose it from `/trips/{id}/position` and `/trips/{id}/eta` per child — a fan-out of N+1 requests on mobile data, at the exact moment the answer matters most.

```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "type": "student",
      "attributes": {
        "displayName": "Aarav Sharma",
        "className": "Class 5-B",
        "journey": {
          "state": "ON_BOARD",
          "tripId": "770e8400-e29b-41d4-a716-446655440010",
          "vehicleDisplayName": "Bus 12",
          "stopName": "Green Park",
          "lastEventAt": "2026-08-03T02:12:00Z",
          "estimatedArrival": "2026-08-03T02:45:00Z",
          "nextDepartureAt": null,
          "positionReceivedAt": "2026-08-03T02:12:11Z",
          "isPositionStale": false
        }
      }
    }
  ],
  "meta": {
    "requestId": "…",
    "timestamp": "2026-08-03T02:12:13Z",
    "school": { "timezoneId": "Asia/Kolkata", "utcOffsetMinutes": 330 }
  }
}
```

**`journey.state`** — `AT_REST` · `SCHEDULED` · `AWAITING_BOARDING` · `ON_BOARD` · `ARRIVED_AT_SCHOOL` · `HANDED_OVER` · `NO_SHOW` · `ABSENT` · `UNACCOUNTED`. New values are additive within `v1`; the parent app renders an unrecognised value as explicitly unknown rather than mapping it onto the nearest familiar state, so a state added after a build shipped can never be displayed as something reassuring.

**`meta.school` is required.** All timestamps are UTC on the wire, and the client renders in the school's timezone (BR-CFG-006). The offset comes from the server rather than a device timezone database, so a parent abroad and a parent at the school gate convert identically.

**`isPositionStale` is always present** (BR-TRACK-003), and is authoritative — the server sees ingestion lag and rejected reports that an age computed from timestamps cannot. The client also derives an age from `timestamp − positionReceivedAt`; where the two disagree, staleness wins.

**`vehicleDisplayName`, never a registration number.** It is what the parent calls the bus.

**`tripId` is present only while live tracking applies** — `ON_BOARD` or `AWAITING_BOARDING`. Tracking is trip-scoped (BR-TRACK-001), so an id the client could not use is not sent at all, and the app has nothing to render a *Track* button from when tracking is unavailable.

**`estimatedArrival`, `positionReceivedAt` and `isPositionStale` come from MOD-10 and are absent until it is built.** `isPositionStale` then defaults to `true` wherever tracking applies, which the app renders as "No signal". That is the honest answer while there is no position pipeline: reporting freshness the platform is not measuring would be the exact failure BR-TRACK-003 exists to prevent.

**No other family's child appears** (BR-NTF-007 🔴), and no student outside the caller's own children (BR-IAM-005) — scoped server-side, with no guardian or student identifier accepted from the client.

### `GET /guardians/me/students/{studentId}`

**Status: implemented** (MOD-18, ADR-0010). Screen P-03.

The same resource as above for one child, with `attributes.legs` added — today's journey in operational order:

```json
{
  "direction": "MORNING",
  "state": "ON_BOARD",
  "vehicleDisplayName": "Bus 12",
  "stopName": "Green Park",
  "scheduledAt": "2026-08-03T01:40:00Z",
  "eventAt": "2026-08-03T02:12:00Z"
}
```

`direction` is `MORNING` / `AFTERNOON` here rather than the operational `PICKUP` / `DROP`: this is parent-facing copy, and a parent reads their day in halves.

A student the caller holds no **active** link to returns `403 AUTH_SCOPE_DENIED` — never `404`. Within a tenant, `403` is the honest answer and avoids a probing oracle that would confirm which children exist at a school.

### `GET /guardians/me/students/{studentId}/journey-history`

**Status: implemented** (MOD-18, ADR-0010). Screen P-05 · Permission `PERM-BOARDING-VIEW`.

The durable record, newest first — one row per leg per day, over the whole of a child's past trips:

```json
{
  "serviceDate": "2026-08-02",
  "direction": "AFTERNOON",
  "state": "HANDED_OVER",
  "vehicleDisplayName": "Bus 12",
  "stopName": "Green Park",
  "eventAt": "2026-08-02T09:50:00Z"
}
```

Driven from `trip_manifests`, not from `boarding_events` — a day a child did **not** board is precisely the day a parent scrolls back to find, and an event-driven query cannot show a leg that produced no event.

Carries `meta.school`, because `eventAt` is UTC and "boarded at 07:42" is only true in the school's zone (BR-CFG-006). Capped server-side; an unbounded read grows for as long as a child is enrolled. Scoped like every other parent read — a student the caller is not linked to returns an empty list, so nothing is learned from the difference between "no history" and "not your child".

---

## Guardian–Student Links 🔴

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/students/{studentId}/guardians` | GRD-001 | `PERM-GUARDIAN-LINK` | BR-GRD-001, BR-GRD-002 |
| `GET` | `/students/{studentId}/guardians` | GRD-002 | `PERM-STUDENT-VIEW` | |
| `PATCH` | `/students/{studentId}/guardians/{linkId}` | GRD-001 | `PERM-GUARDIAN-LINK` | BR-GRD-001 |
| `DELETE` | `/students/{studentId}/guardians/{linkId}` | GRD-003 | `PERM-GUARDIAN-LINK` | BR-GRD-002, BR-GRD-004 |

```json
{
  "guardianId": "…",
  "relationshipType": "MOTHER",
  "canView": true,
  "canReceiveNotifications": true,
  "canAuthoriseHandover": true,
  "canDeclareAbsence": true,
  "isPrimary": true
}
```

### Rights are explicit, never inferred

`relationshipType` is **descriptive only**. The four booleans are authoritative (BR-GRD-001 🔴). Inferring "father ⇒ may collect" would encode an assumption that is wrong precisely in the cases where being wrong causes harm — custody arrangements, restricted parents (BR-GRD-008).

`canAuthoriseHandover` defaults to `false`. Rights are granted deliberately.

**`DELETE` is refused** if it would leave the student with no guardian holding `canAuthoriseHandover` — `422 GUARDIAN_HANDOVER_RIGHT_REQUIRED` (BR-GRD-002 🔴). Otherwise the child could arrive at a drop stop with nobody authorised to receive them.

Deactivation takes effect immediately: access removed, notifications stopped (BR-GRD-004).

---

## Authorised Pickup Persons

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/students/{studentId}/pickup-persons` | GRD-004 | `PERM-PICKUP-PERSON-MANAGE` | BR-GRD-005, BR-GRD-006 |
| `GET` | `/students/{studentId}/pickup-persons` | GRD-004 | `PERM-STUDENT-VIEW` | |
| `DELETE` | `/students/{studentId}/pickup-persons/{id}` | GRD-005 | `PERM-PICKUP-PERSON-MANAGE` | BR-GRD-007 |

```json
{
  "fullName": "Sunil Kumar",
  "phone": "+919812345678",
  "relationshipNote": "Uncle",
  "validFrom": "2026-08-05T00:00:00Z",
  "validUntil": "2026-08-12T23:59:59Z"
}
```

**`validUntil` is required.** Nominations always expire — a permanent nomination made once and forgotten is a standing authorisation nobody reviews. Extending is an explicit act.

Only a guardian holding `canAuthoriseHandover` may nominate (BR-GRD-006) — otherwise `403 GUARDIAN_NOT_AUTHORISED_TO_NOMINATE`. The nomination is audited and **all** guardians with that right are notified (NTF-ADM-04), so one guardian cannot quietly authorise someone the others would object to.

Revocation is immediate (BR-GRD-007).

---

## Custody Restrictions 🔴

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/students/{studentId}/custody-restrictions` | GRD-006 | `PERM-CUSTODY-RESTRICTION-MANAGE` | BR-GRD-008 |
| `GET` | `/students/{studentId}/custody-restrictions` | GRD-006 | `PERM-CUSTODY-RESTRICTION-MANAGE` | |
| `DELETE` | `/students/{studentId}/custody-restrictions/{id}` | GRD-006 | `PERM-CUSTODY-RESTRICTION-MANAGE` | BR-GRD-008 |

```json
{
  "restrictedGuardianId": "…",
  "restrictionType": "NO_HANDOVER",
  "reason": "Court order dated 2026-06-12, reference …",
  "effectiveFrom": "2026-06-15T00:00:00Z"
}
```

**Exactly one of `restrictedGuardianId` / `restrictedPersonName`** — a guardian on file, or a
named non-guardian. Neither or both → `422 CUSTODY_RESTRICTION_SUBJECT_REQUIRED`. A
`restrictedGuardianId` that resolves to nobody is the same error. `restrictionType` is
`NO_HANDOVER` / `NO_VISIBILITY` / `FULL`. `effectiveFrom` defaults to now; `effectiveUntil` is
optional (an open-ended restriction). `GET` returns active **and** lifted restrictions, newest
first, so the screen shows the history. `DELETE` deactivates — an unknown id, or one not for
the student in the path, is `404 CUSTODY_RESTRICTION_NOT_FOUND`.

**Overrides every other permission.** A restriction beats an active guardian link granting `canAuthoriseHandover` (BR-HAND-006 🔴). A collection attempt by a restricted person is refused, recorded as a `HANDOVER_REFUSED` incident, and escalated (NTF-HAND-04).

`reason` is required and stored on the audit record. Restrictions are visible only to holders of `PERM-CUSTODY-RESTRICTION-MANAGE` — never to the restricted person, and never exposed in any guardian-facing response.

---

## Guardian Self-Service

| Method | Path | Feature | Permission |
|---|---|---|---|
| `GET` | `/guardians/me/students` | GRD-007 | authenticated |
| `GET` | `/guardians/me/preferences` | GRD-007 | `PERM-NOTIFICATION-PREFERENCE-SELF` |
| `PUT` | `/guardians/me/preferences` | GRD-007 | `PERM-NOTIFICATION-PREFERENCE-SELF` |

Attempting to disable a `CRITICAL` notification returns `422 NOTIFICATION_PREFERENCE_NOT_APPLICABLE` (BR-NTF-006 🔴). A parent may mute everything else *because* the events that matter always arrive.

---

## Verification

1. A guardian requesting another family's student receives `403`.
2. Every non-guardian student read writes a data-access record.
3. Removing the last handover-capable guardian is refused.
4. A guardian without `canAuthoriseHandover` cannot nominate a pickup person.
5. A pickup nomination without `validUntil` is rejected.
6. A custody restriction blocks handover despite an active guardian link granting it.
7. Custody restrictions never appear in guardian-facing responses.
8. Student photos are unreachable without permission and scope.
9. Import with 4 bad rows imports the other 408 and reports the 4.
10. A student credential's raw value is returned once and never retrievable again.
11. Discarding a student with any boarding, absence, or notification history returns `422` and changes no row.
12. Discarding a mistaken student removes it with its links and assignments, and writes `STUDENT_DISCARDED`.
13. Correcting a guardian's phone revokes every session of the old number's account.
