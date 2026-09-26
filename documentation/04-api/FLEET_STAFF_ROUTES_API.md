# FLEET, STAFF & ROUTES API

**Document tier:** 4 — API
**Modules:** MOD-05, MOD-06, MOD-07 · **Features:** FLT-001…005, STF-001…007, RTE-001…007

---

## Vehicles

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/vehicles` | FLT-001 | `PERM-VEHICLE-MANAGE` | BR-FLEET-001, BR-FLEET-005 |
| `GET` | `/vehicles` | FLT-001 | `PERM-VEHICLE-VIEW` | BR-IAM-006 |
| `GET` | `/vehicles/{id}` | FLT-001 | `PERM-VEHICLE-VIEW` | |
| `PATCH` | `/vehicles/{id}` | FLT-001 | `PERM-VEHICLE-MANAGE` | |
| `GET` | `/vehicles/{id}/eligibility` | FLT-003 | `PERM-VEHICLE-VIEW` | BR-FLEET-002 |

```json
{
  "schoolId": "…", "registrationNo": "DL1PC1234", "displayName": "Bus 12",
  "vehicleType": "BUS", "seatingCapacity": 42, "vendorName": "Sharma Transport"
}
```

`displayName` is what parents see in notifications — "Bus 12", not a plate number (NTF-BOARD-01).

### `GET /vehicles/{id}/eligibility`

```json
{
  "data": {
    "eligible": false,
    "checks": [
      { "check": "VEHICLE_ACTIVE", "passed": true },
      { "check": "MANDATORY_DOCUMENTS_VALID", "passed": false,
        "detail": "Fitness certificate expired 2026-07-15", "businessRule": "BR-FLEET-002" }
    ]
  }
}
```

Lets a manager see *why* a vehicle is blocked before 6:30 AM, rather than discovering it when a driver cannot start.

---

## Vehicle Documents 🔴

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/vehicles/{id}/documents` | FLT-002 | `PERM-VEHICLE-DOCUMENT-MANAGE` | BR-FLEET-002 |
| `GET` | `/vehicles/{id}/documents` | FLT-002 | `PERM-VEHICLE-VIEW` | |
| `PATCH` | `/vehicles/{id}/documents/{docId}` | FLT-002 | `PERM-VEHICLE-DOCUMENT-MANAGE` | |
| `GET` | `/vehicles/documents/expiring` | FLT-003 | `PERM-VEHICLE-VIEW` | BR-FLEET-003 |

```json
{ "documentType": "FITNESS_CERTIFICATE", "documentNumber": "…",
  "issuedOn": "2025-08-01", "expiresOn": "2026-08-01" }
```

**`documentType` is validated against the region profile, not a code enum** (ADR-0007). Registration, fitness, insurance, and permit types differ by country; a code enum would mean a code change to onboard a new market.

**What is not configurable:** an expired mandatory document blocks trip assignment (BR-FLEET-002 🔴). Tenants configure which documents are mandatory; they cannot configure the block away.

---

## Devices

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/devices` | FLT-004 | `PERM-DEVICE-MANAGE` | BR-FLEET-006 |
| `GET` | `/devices` | FLT-004 | `PERM-DEVICE-MANAGE` | |
| `PUT` | `/devices/{id}/vehicle` | FLT-004 | `PERM-DEVICE-MANAGE` | BR-FLEET-004 |
| `DELETE` | `/devices/{id}/vehicle` | FLT-004 | `PERM-DEVICE-MANAGE` | |

Assigning a second active device to a vehicle returns `409 DEVICE_ALREADY_ASSIGNED` (BR-FLEET-004) — two devices reporting for one bus would produce contradictory positions.

Devices are **explicitly registered**. An unregistered device's position report is logged and ignored, never auto-registered (BR-FLEET-006) — auto-registration would let anyone inject positions for a vehicle they do not own.

---

## Transport Staff

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/transport-staff` | STF-001 | `PERM-STAFF-MANAGE` | |
| `GET` | `/transport-staff` | STF-001 | `PERM-STAFF-VIEW` | BR-IAM-006 |
| `GET` | `/transport-staff/{id}` | STF-001 | `PERM-STAFF-VIEW` | BR-IAM-006 |
| `PATCH` | `/transport-staff/{id}` | STF-001 | `PERM-STAFF-MANAGE` | BR-IAM-014 |
| `POST` | `/transport-staff/{id}/verify` | STF-003 | `PERM-STAFF-VERIFY` | BR-STAFF-002 |
| `POST` | `/transport-staff/{id}/credentials` | STF-002 | `PERM-STAFF-MANAGE` | BR-STAFF-001 |
| `GET` | `/transport-staff/{id}/eligibility` | STF-003 | `PERM-STAFF-MANAGE` | BR-STAFF-001/002 |
| `GET` | `/transport-staff/credentials/expiring` | STF-002 | `PERM-STAFF-MANAGE` | BR-STAFF-003 |
| `POST` | `/transport-staff/{id}/deactivate` | IAM-008 | `PERM-STAFF-MANAGE` | BR-IAM-008 |
| `POST` | `/transport-staff/{id}/discard` | STF-007 | `PERM-STAFF-DELETE` | BR-STAFF-007 |

Reading the register needs only `PERM-STAFF-VIEW`, which `PRINCIPAL` holds without `PERM-STAFF-MANAGE` (ADR-0019).

### `PATCH /transport-staff/{id}`

Corrects name, phone, employee code, and vendor name. **Changing the phone moves the staff member's sign-in to the new number** (BR-IAM-014, [ADR-0019](../00-governance/adr/ADR-0019-discarding-mistaken-entries-and-phone-correction.md)):

1. The new number's account is reused or created, and granted `DRIVER` or `ATTENDANT`.
2. The record is relinked to it.
3. The old number's account loses that role and **every session, immediately**. With no role left it becomes `INACTIVE`.

Correcting only the roster copy would leave the one-time codes going to the wrong phone.

### `POST /transport-staff/{id}/discard`

Permanently removes a driver or attendant record **entered by mistake** (STF-007, BR-STAFF-007).

```json
{ "reason": "Entered under the wrong school" }
```

- `reason` is required, 1–500 characters.
- **Refused with `422 STAFF_HAS_SAFETY_RECORDS` if their sign-in account has ever signed in**, or if anything besides their own credential documents and duty assignments references the record. Deactivate such a staff member instead (BR-IAM-008).
- In one transaction: credential documents and duty assignments are removed, then the record. The sign-in account is released — role and sessions revoked, `INACTIVE` with no role left — never deleted.
- A school-scoped caller may discard only within their school; any other record answers `404 STAFF_NOT_FOUND`.
- Audited as `TRANSPORT_STAFF_DISCARDED` with the reason, staff type, employee code, school, and counts removed — never name or phone.
- Answers `204 No Content`.

### `POST /transport-staff/{id}/verify`

```json
{ "verificationType": "POLICE_BACKGROUND_CHECK", "verifiedUntil": "2027-08-03", "referenceNumber": "…" }
```

**`verifiedUntil` is required** — a permanently-verified staff member is a verification nobody will ever revisit (BR-STAFF-002 🔴). Verification types come from the region profile.

Deactivation revokes all sessions immediately and removes future duty assignments (BR-IAM-008).

---

## Duty Assignments

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/routes/{routeId}/duty-assignments` | STF-004 | `PERM-DUTY-ASSIGN` | BR-STAFF-004, BR-STAFF-005 |
| `GET` | `/routes/{routeId}/duty-assignments` | STF-004 | `PERM-ROUTE-VIEW` | |
| `POST` | `/duty-assignments/{id}/replace` | STF-004 | `PERM-DUTY-ASSIGN` | BR-STAFF-004, BR-IAM-008, BR-AUD-002 |
| `DELETE` | `/duty-assignments/{id}` | STF-004 | `PERM-DUTY-ASSIGN` | |

The **standing roster**. Actual crew for a specific trip is `trip_staff` — separated so a substitution does not rewrite the roster (BR-STAFF-006).

`GET` returns each duty with the holder's name (`staffFirstName`, `staffLastName`) as well as `staffId`: a roster of ids cannot be read by the person replacing an absent driver. A duty whose staff record has gone keeps its row with empty names, so an unfilled crew slot stays visible.

### `POST /duty-assignments/{id}/replace`

Puts a different person on an existing duty — the regular driver has left, or is away long enough that the roster itself should change.

```json
{ "staffId": "…", "reason": "Suresh on leave from today" }
```

- The replacement **inherits the role and direction** of the duty it takes over; neither is sent. Changing who drives and what they drive are two decisions.
- Old off and new on **in one transaction**: the route is never left with two active crew in one role, nor with none because a second call failed.
- `reason` is required, 1–500 characters, and is audited as `DUTY_ASSIGNMENT_REPLACED` with both staff ids — every driver and attendant change is recorded with why.
- A deactivated staff member cannot take the duty (BR-IAM-008) → `404 STAFF_NOT_FOUND`, as for an unknown one. Licence and verification are checked when a trip starts (BR-STAFF-001/002), not here.
- Replacing someone with themselves is refused (`400 VALIDATION_VALUE_OUT_OF_RANGE`), like any other malformed request.
- **This is not a one-day substitution.** A stand-in for a single run belongs to that trip (`trip_staff`, BR-STAFF-006, STF-005) and needs MOD-08.

---

## Routes

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/routes` | RTE-001 | `PERM-ROUTE-MANAGE` | BR-ROUTE-001 |
| `GET` | `/routes` | RTE-001 | `PERM-ROUTE-VIEW` | BR-IAM-006 |
| `GET` | `/routes/{id}` | RTE-001 | `PERM-ROUTE-VIEW` | |
| `PATCH` | `/routes/{id}` | RTE-005 | `PERM-ROUTE-MANAGE` | BR-ROUTE-006 |
| `DELETE` | `/routes/{id}` | RTE-006 | `PERM-ROUTE-MANAGE` | BR-ROUTE-007 |
| `PUT` | `/routes/{id}/stops` | RTE-001 | `PERM-ROUTE-MANAGE` | BR-ROUTE-002/003/008/009 |
| `GET` | `/routes/{id}/stops` | RTE-001 | `PERM-ROUTE-VIEW` | |

### `POST /routes` and `PATCH /routes/{id}`

```json
{ "schoolId": "…", "code": "R3", "name": "Green Park",
  "defaultVehicleId": "…", "operatingDays": "MON,TUE,WED,THU,FRI" }
```

`operatingDays` is a comma-separated list of three-letter day codes, and it is the field that decides whether a bus runs at all: MOD-08 generates a trip only for a day listed here (BR-TRIP-011). Omitting it on `POST` means the five-day school week, matching the column default. Order is not significant on the way in and is normalised to calendar order on the way out, so two routes running the same days store the same string. An unrecognised code is **refused**, never skipped — a silently dropped `TEU` produces a route that stops running on Tuesdays and tells nobody.

`PATCH` carries only the fields being changed; anything omitted is left alone. Three fields are **not** accepted:

| Field | Why |
|---|---|
| `code` | It is printed on lists, quoted to parents, and stamped on every trip generated under the route. Changing it re-labels history that has already been acted on; retire the route and create its replacement instead. |
| `schoolId` | Moving a route between schools would orphan its stops, its student assignments and its duty roster in one statement. |
| `active` | Deactivating is conditional on reassigning or explicitly releasing every student on the route (BR-ROUTE-007). That check is not built, and a flag that flipped without it would strand children on a route that silently stops generating trips. **`DELETE /routes/{id}` ships with that rule.** |

Both are audited with before and after values (BR-AUD-002). "Who stopped the Saturday service?" is a question asked on a Saturday morning, and a record holding only the new value cannot answer it.

### `PUT /routes/{id}/stops`

```json
{
  "stops": [
    { "id": "…", "sequenceNo": 1, "name": "Green Park", "latitude": 28.5601, "longitude": 77.2065,
      "geofenceRadiusM": 100, "scheduledPickupTime": "07:40", "scheduledDropTime": "15:20",
      "landmark": "Opposite the metro gate 3" }
  ]
}
```

Replaces the full ordered list — partial stop edits invite sequence gaps and ordering bugs.

**A kept stop keeps its identity.** Send an existing stop's `id` to keep it: it is updated in place, so every student assigned to it stays assigned. A stop without `id` is new. An existing stop left out of the list is removed — deactivated, never deleted, because trips that already ran reference it.

**Validation:**
- At least two stops (BR-ROUTE-001) → `422 ROUTE_MINIMUM_STOPS_REQUIRED`
- Geofence radius 20–500 m (BR-ROUTE-003, BR-CFG-003 🔴) → `422 ROUTE_GEOFENCE_OUT_OF_BOUNDS`
- An `id` that is not one of this route's current stops, or appears twice → `404 ROUTE_STOP_NOT_FOUND`
- Removing a stop a student is still assigned to (BR-ROUTE-009) → `422 ROUTE_STOP_HAS_ASSIGNED_STUDENTS`, with the stop ids in `details`. Move the students first.
- Strictly increasing times in visiting order (BR-ROUTE-008) → `422 ROUTE_STOP_TIMES_NOT_INCREASING`. Pickup times increase with `sequenceNo`; drop times increase as `sequenceNo` *decreases*, since the afternoon run returns from school and drops the last stop first. The `details` entry with `field: "sequenceNo"` names the offending stop.

The geofence bounds are not arbitrary: below 20 m, GPS drift means arrival is never detected and parents get no notification; above 500 m, geofences overlap and arrival events become meaningless ([`MOD-07-routes.md`](../03-database/tables/MOD-07-routes.md)).

**Editing stops does not alter trips already started** (BR-ROUTE-006) — the manifest is materialised at trip start and immutable (BR-TRIP-003).

### `DELETE /routes/{id}`

Refused while students remain assigned — `422 ROUTE_HAS_ACTIVE_ASSIGNMENTS` (BR-ROUTE-007). Reassign or explicitly release first, so no child is silently left without transport.

---

## Student Route Assignments

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/routes/{routeId}/students` | RTE-003 | `PERM-ROUTE-ASSIGN-STUDENT` | BR-ROUTE-004, BR-STU-002 |
| `POST` | `/routes/{routeId}/students/bulk` | RTE-004 | `PERM-ROUTE-ASSIGN-STUDENT` | BR-ROUTE-004 |
| `GET` | `/routes/{routeId}/students` | RTE-003 | `PERM-ROUTE-VIEW` | |
| `DELETE` | `/route-assignments/{id}` | RTE-003 | `PERM-ROUTE-ASSIGN-STUDENT` | |
| `GET` | `/students/{studentId}/route-assignments` | RTE-003 | `PERM-STUDENT-VIEW` | BR-ROUTE-005 |

```json
{ "studentId": "…", "stopId": "…", "direction": "PICKUP", "effectiveFrom": "2026-08-05" }
```

**Preconditions**, each with a distinct error:

| Condition | Error | Rule |
|---|---|---|
| Student has no active guardian | `422 STUDENT_HAS_NO_ACTIVE_GUARDIAN` | BR-STU-002 |
| No guardian holds handover right | `422 GUARDIAN_HANDOVER_RIGHT_REQUIRED` | BR-GRD-002 🔴 |
| Student not actively enrolled | `422 STUDENT_NOT_ACTIVE` | BR-STU-004 |
| Already assigned for this direction | `409 STUDENT_ALREADY_ASSIGNED_FOR_DIRECTION` | BR-ROUTE-004 |

The third check is the important one: **a child must not be assigned to transport if nobody is authorised to collect them.**

A student may hold pickup on one route and drop on another (BR-ROUTE-005) — common where a parent drops off but the bus returns.

Bulk assignment reports per-row results like student import.

---

## Verification

1. A vehicle with an expired mandatory document reports `eligible: false` with the specific check.
2. A second active device for one vehicle is rejected.
3. An unregistered device's position report is ignored, not auto-registered.
4. Verifying staff without `verifiedUntil` is rejected.
4a. Discarding a staff member whose account has signed in returns `422` and changes no row.
4b. Correcting a driver's phone leaves the old number's account without the role and with no live session.
5. A stop with a geofence radius of 10 m or 800 m is rejected.
6. Stop times not strictly increasing are rejected.
7. Editing stops does not change an in-progress trip's manifest.
8. Deleting a route with active assignments is refused.
9. Assigning a student whose guardians lack the handover right is refused.
10. A student may hold pickup on route A and drop on route B.
