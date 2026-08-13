# FLEET, STAFF & ROUTES API

**Document tier:** 4 — API
**Modules:** MOD-05, MOD-06, MOD-07 · **Features:** FLT-001…005, STF-001…006, RTE-001…007

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
| `GET` | `/transport-staff` | STF-001 | `PERM-STAFF-MANAGE` | BR-IAM-006 |
| `PATCH` | `/transport-staff/{id}` | STF-001 | `PERM-STAFF-MANAGE` | |
| `POST` | `/transport-staff/{id}/verify` | STF-003 | `PERM-STAFF-VERIFY` | BR-STAFF-002 |
| `POST` | `/transport-staff/{id}/credentials` | STF-002 | `PERM-STAFF-MANAGE` | BR-STAFF-001 |
| `GET` | `/transport-staff/{id}/eligibility` | STF-003 | `PERM-STAFF-MANAGE` | BR-STAFF-001/002 |
| `GET` | `/transport-staff/credentials/expiring` | STF-002 | `PERM-STAFF-MANAGE` | BR-STAFF-003 |
| `POST` | `/transport-staff/{id}/deactivate` | IAM-008 | `PERM-STAFF-MANAGE` | BR-IAM-008 |

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
| `DELETE` | `/duty-assignments/{id}` | STF-004 | `PERM-DUTY-ASSIGN` | |

The **standing roster**. Actual crew for a specific trip is `trip_staff` — separated so a substitution does not rewrite the roster (BR-STAFF-006).

---

## Routes

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/routes` | RTE-001 | `PERM-ROUTE-MANAGE` | BR-ROUTE-001 |
| `GET` | `/routes` | RTE-001 | `PERM-ROUTE-VIEW` | BR-IAM-006 |
| `GET` | `/routes/{id}` | RTE-001 | `PERM-ROUTE-VIEW` | |
| `PATCH` | `/routes/{id}` | RTE-005 | `PERM-ROUTE-MANAGE` | BR-ROUTE-006 |
| `DELETE` | `/routes/{id}` | RTE-006 | `PERM-ROUTE-MANAGE` | BR-ROUTE-007 |
| `PUT` | `/routes/{id}/stops` | RTE-001 | `PERM-ROUTE-MANAGE` | BR-ROUTE-002/003/008 |
| `GET` | `/routes/{id}/stops` | RTE-001 | `PERM-ROUTE-VIEW` | |

### `PUT /routes/{id}/stops`

```json
{
  "stops": [
    { "sequenceNo": 1, "name": "Green Park", "latitude": 28.5601, "longitude": 77.2065,
      "geofenceRadiusM": 100, "scheduledPickupTime": "07:40", "scheduledDropTime": "15:20",
      "landmark": "Opposite the metro gate 3" }
  ]
}
```

Replaces the full ordered list — partial stop edits invite sequence gaps and ordering bugs.

**Validation:**
- At least two stops (BR-ROUTE-001) → `422 ROUTE_MINIMUM_STOPS_REQUIRED`
- Geofence radius 20–500 m (BR-ROUTE-003, BR-CFG-003 🔴) → `422 ROUTE_GEOFENCE_OUT_OF_BOUNDS`
- Strictly increasing times along the sequence (BR-ROUTE-008) → `422 ROUTE_STOP_TIMES_NOT_INCREASING`

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
5. A stop with a geofence radius of 10 m or 800 m is rejected.
6. Stop times not strictly increasing are rejected.
7. Editing stops does not change an in-progress trip's manifest.
8. Deleting a route with active assignments is refused.
9. Assigning a student whose guardians lack the handover right is refused.
10. A student may hold pickup on route A and drop on route B.
