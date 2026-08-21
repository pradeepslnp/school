# TEST CASES

**Document tier:** 7 — Testing
**Status:** Active

Feature-level test cases, keyed to feature IDs from [`FEATURE_INVENTORY.md`](../01-product-discovery/FEATURE_INVENTORY.md).

Format `TC-<FEATURE>-<nn>`. Safety-critical coverage is in [`SAFETY_CRITICAL_TEST_MATRIX.md`](SAFETY_CRITICAL_TEST_MATRIX.md); this document covers the rest.

---

## Tenancy (TEN)

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-TEN-01 | TEN-001 | Create organization with a region profile | Defaults seeded from the profile; no code path selects on country |
| TC-TEN-02 | TEN-001 | Duplicate organization code | `409 ORG_CODE_ALREADY_EXISTS` |
| TC-TEN-03 | TEN-002 | Create school without timezone | `400` — required |
| TC-TEN-04 | TEN-002 | Remove last school of an active organization | `422 ORG_LAST_SCHOOL_CANNOT_BE_REMOVED` |
| TC-TEN-05 | TEN-002 | Move school between organizations | `422 SCHOOL_CANNOT_CHANGE_ORGANIZATION` |
| TC-TEN-06 | TEN-004 | Suspend organization with a trip in progress | Access blocked; **safety recording continues** |
| TC-TEN-07 | TEN-003 | Tenant not using branches | Null `branchId` accepted everywhere |
| TC-TEN-08 | TEN-005 | Holiday in calendar | No trips generated for that date |

---

## Identity (IAM)

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-IAM-01 | IAM-001 | Login, wrong password | `401 AUTH_CREDENTIALS_INVALID` |
| TC-IAM-02 | IAM-001 | Login, unknown email | **Same** error — no account enumeration |
| TC-IAM-03 | IAM-002 | OTP request, unregistered number | `202`, identical response |
| TC-IAM-04 | IAM-002 | OTP reuse | `401 AUTH_OTP_ALREADY_USED` |
| TC-IAM-05 | IAM-003 | Refresh rotates token | New pair; old refresh unusable |
| TC-IAM-06 | IAM-003 | Reuse consumed refresh | Family revoked, alert raised (NTF-SEC-02) |
| TC-IAM-07 | IAM-006 | Remove permission from role | Effective on the **next request**, no re-login |
| TC-IAM-08 | IAM-008 | Deactivate staff member | All sessions revoked immediately |
| TC-IAM-09 | IAM-011 | Repeated failed logins | Lockout per BR-IAM-011 |
| TC-IAM-10 | IAM-007 | Set a derived scope (`OWN_CHILDREN`) | `400` — derived, not settable |

---

## Students & Guardians (STU / GRD)

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-STU-01 | STU-002 | Import 412 rows, 4 invalid | 408 imported, 4 reported, error file downloadable |
| TC-STU-02 | STU-002 | Duplicate admission number | Row fails; others succeed |
| TC-STU-03 | STU-004 | Withdraw student with safety records | Status changed; **records retained** |
| TC-STU-04 | STU-006 | Photo requested without permission | `403` — never a public URL |
| TC-STU-05 | STU-007 | Issue credential | Raw value returned **once**; stored hashed |
| TC-STU-06 | STU-007 | Scan revoked credential | `422 BOARDING_CREDENTIAL_INVALID` |
| TC-GRD-01 | GRD-001 | Link guardian with explicit rights | Rights stored as given; not inferred from relationship |
| TC-GRD-02 | GRD-004 | Nominate pickup person without expiry | `400` — `validUntil` required |
| TC-GRD-03 | GRD-004 | Nominate pickup person | **All** handover-capable guardians notified |
| TC-GRD-04 | GRD-005 | Revoke pickup person | Effective immediately at next handover |
| TC-GRD-05 | GRD-005 | Handover to expired nomination | `422 PICKUP_PERSON_OUTSIDE_VALIDITY` |

---

## Fleet & Staff (FLT / STF)

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-FLT-01 | FLT-002 | Document type from a second region profile | Accepted; no code change needed |
| TC-FLT-02 | FLT-003 | Document approaching expiry | Escalating warnings at configured intervals |
| TC-FLT-03 | FLT-004 | Assign second active device to a vehicle | `409 DEVICE_ALREADY_ASSIGNED` |
| TC-FLT-04 | FLT-004 | Position from unregistered device | Logged and ignored; **not auto-registered** |
| TC-FLT-05 | FLT-005 | Assign students beyond seating capacity | Warning; audited override required |
| TC-STF-01 | STF-003 | Verify staff without `verifiedUntil` | Rejected — no permanent verification |
| TC-STF-02 | STF-002 | Credential expires | Future assignment blocked; warnings raised |
| TC-STF-03 | STF-004 | Assign staff already on an active trip | `409 STAFF_ALREADY_ON_ACTIVE_TRIP` |
| TC-STF-04 | STF-005 | Mid-trip substitution | Both crew rows retained, linked, timed |

---

## Routes (RTE)

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-RTE-01 | RTE-001 | Route with one stop | `422 ROUTE_MINIMUM_STOPS_REQUIRED` |
| TC-RTE-02 | RTE-002 | Geofence radius 10 m / 800 m | `422 ROUTE_GEOFENCE_OUT_OF_BOUNDS` |
| TC-RTE-03 | RTE-001 | Stop times not increasing | `422 ROUTE_STOP_TIMES_NOT_INCREASING` |
| TC-RTE-04 | RTE-003 | Second active pickup assignment for a student | `409` — rejected by constraint |
| TC-RTE-05 | RTE-003 | Pickup on route A, drop on route B | Accepted (BR-ROUTE-005) |
| TC-RTE-06 | RTE-003 | Assign student with no handover-capable guardian | `422 GUARDIAN_HANDOVER_RIGHT_REQUIRED` |
| TC-RTE-07 | RTE-006 | Deactivate route with assignments | `422 ROUTE_HAS_ACTIVE_ASSIGNMENTS` |
| TC-RTE-08 | RTE-005 | Edit stops after a trip started | In-progress manifest unchanged |

---

## Trips (TRP)

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-TRP-01 | TRP-001 | Generate trips across a holiday | No trips on the holiday |
| TC-TRP-02 | TRP-002 | Start with expired vehicle document | `422 VEHICLE_DOCUMENT_EXPIRED` — **names the document** |
| TC-TRP-03 | TRP-002 | Start with expired driver licence | `422 STAFF_LICENCE_EXPIRED` |
| TC-TRP-04 | TRP-002 | Start when attendant is mandatory and absent | `422 ATTENDANT_REQUIRED` |
| TC-TRP-05 | TRP-003 | Start with a declared absence | Student excluded from manifest |
| TC-TRP-06 | TRP-004 | `SCHEDULED` → `CLOSED` directly | `409 TRIP_INVALID_STATUS_TRANSITION` |
| TC-TRP-07 | TRP-005 | Cancel without a reason | `422 TRIP_CANCELLATION_REASON_REQUIRED` |
| TC-TRP-08 | TRP-005 | Cancel a trip | All affected guardians notified with the reason |
| TC-TRP-09 | TRP-007 | Trip not started within window | Delay alert to manager and guardians |
| TC-TRP-10 | TRP-006 | Amendment without a reason | `422` — rejected |

---

## Boarding (BRD)

Beyond the safety matrix:

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-BRD-01 | BRD-001 | Scan a valid credential | Boarding recorded; guardians notified within budget |
| TC-BRD-02 | BRD-002 | Manual mark from manifest | Recorded with `MANUAL` verification method |
| TC-BRD-03 | BRD-001 | Board twice without alighting | `409 BOARDING_ALREADY_BOARDED` |
| TC-BRD-04 | BRD-003 | Alight without boarding | `422 BOARDING_NOT_BOARDED` |
| TC-BRD-05 | BRD-004 | Batch sync with one conflicting event | Others succeed; conflict **flagged**, not rejected |
| TC-BRD-06 | BRD-005 | Correct a mis-scan | New record with `correctsEventId`; both readable |
| TC-BRD-07 | BRD-006 | Off-manifest boarding with override | Recorded with reason; audited |
| TC-BRD-08 | BRD-015 | Depart with un-boarded student | No-show recorded; guardians notified |
| TC-BRD-09 | BRD-011 | Self-release where configured | Recorded as self-release; guardians notified |

---

## Tracking & Alerts (TRK / ALT)

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-TRK-01 | TRK-001 | Position with implausible speed | Rejected and logged; **not stored** |
| TC-TRK-02 | TRK-001 | Out-of-order reports after a gap | Live position not moved backwards; history retains all |
| TC-TRK-03 | TRK-002 | Position requested outside an active trip | `422 TRACKING_NOT_AVAILABLE_OUTSIDE_TRIP` |
| TC-TRK-04 | TRK-003 | Guardian requests another trip's position | `403` |
| TC-TRK-05 | TRK-003 | Redis unavailable | Tracking degrades; ingestion and boarding unaffected |
| TC-TRK-06 | TRK-005 | Routing provider unavailable | ETA returned with `confidence: LOW` |
| TC-TRK-07 | TRK-006 | History query for one day | Exactly one partition scanned |
| TC-TRK-08 | TRK-007 | No reports during an active trip | Signal-loss alert to manager |
| TC-ALT-01 | ALT-004 | Brief GPS wander outside the corridor | **No alert** — duration threshold not met |
| TC-ALT-02 | ALT-004 | Sustained deviation | One alert; `lastObservedAt` advances |
| TC-ALT-03 | ALT-005 | Momentary speed spike | **No alert** — sustained-condition rule |
| TC-ALT-04 | ALT-007 | Resolve alert without an outcome | `422 ALERT_RESOLUTION_OUTCOME_REQUIRED` |

TC-ALT-01 and TC-ALT-03 test the *absence* of alerts. False positives destroy a manager's trust in the alert stream, which makes the real alert invisible.

---

## Notification (NTF)

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-NTF-01 | NTF-001 | Guardian without notification right | Not a recipient |
| TC-NTF-02 | NTF-002 | Missing template in user's locale | Falls back; **gap logged** |
| TC-NTF-03 | NTF-007 | Standard notification during quiet hours | **Deferred, then delivered** — never discarded |
| TC-NTF-04 | NTF-008 | Attempt to disable a `CRITICAL` preference | `422 NOTIFICATION_PREFERENCE_NOT_APPLICABLE` |
| TC-NTF-05 | NTF-009 | Push fails, SMS succeeds | Both attempts recorded; fallback flagged |
| TC-NTF-06 | NTF-003 | Domain event redelivered | Exactly one notification per recipient/channel |
| TC-NTF-07 | NTF-001 | Guardian with two children on one trip | Coalesced into one message |

---

## Absence, Incidents, Reporting, Config

| ID | Feature | Case | Expected |
|---|---|---|---|
| TC-ABS-01 | ABS-001 | Absence before trip start | Excluded from manifest; no-show suppressed |
| TC-ABS-02 | ABS-004 | Absence after trip start | `422`; amendment path offered |
| TC-ABS-03 | ABS-003 | Cancel absence after start | `422 ABSENCE_CANNOT_CANCEL_AFTER_START` |
| TC-ABS-04 | ABS-005 | Absent student boards anyway | Alert raised; **both facts recorded** |
| TC-INC-01 | INC-003 | Resolve SOS as false alarm | Recorded as outcome; **not deleted** |
| TC-INC-02 | INC-005 | Trip-wide incident notification | **No student named** |
| TC-INC-03 | INC-006 | Close incident without an outcome | `422 INCIDENT_RESOLUTION_REQUIRED` |
| TC-RPT-01 | RPT-001 | Report requested by a scoped user | Only in-scope data; scope applied in-query |
| TC-RPT-02 | RPT-001 | Any report response | Includes `timezone` and `generatedAt` |
| TC-RPT-03 | RPT-006 | Export child data | Audit record with actor, scope, **record count** |
| TC-RPT-04 | RPT-006 | Reuse an export download link | Refused — single-use, expiring |
| TC-CFG-01 | CFG-004 | Set value outside bounds | `422 CONFIG_VALUE_OUT_OF_BOUNDS` |
| TC-CFG-02 | CFG-002 | School override of an org value | School value wins (BR-CFG-002) |
| TC-CFG-03 | CFG-005 | Change any configuration value | Audited with old and new values |
| TC-CFG-04 | CFG-003 | Onboard a tenant in a second region | Different phone rules, documents, formats — **no code branch on country** |
| TC-CFG-05 | CFG-007 | Two schools in different timezones | Each renders its own local times |

TC-CFG-04 is the test ADR-0007 sets for itself: *if a new customer in a new country requires a code change, the design has failed.*

---

## Coverage Check

CI asserts every `R1` feature ID in [`FEATURE_INVENTORY.md`](../01-product-discovery/FEATURE_INVENTORY.md) appears in this document or the safety matrix. A feature with no test case fails the build.
