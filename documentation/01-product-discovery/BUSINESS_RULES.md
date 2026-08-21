# BUSINESS RULES

**Document tier:** 1 — Product Discovery
**Priority:** 5 — outranks system design, database, API, and UI
**Status:** Active

Every rule is numbered, testable, and traceable. **Each rule ID must be referenced by at least one test** ([`DOCUMENT_HIERARCHY.md`](../00-governance/DOCUMENT_HIERARCHY.md) traceability invariant 2).

Rules marked 🔴 are **safety-critical**: they may not be disabled by configuration, and changing one requires an ADR.

---

## BR-TEN — Tenancy

| ID | Rule |
|---|---|
| BR-TEN-001 | Every tenant-scoped record belongs to exactly one organization. An organization is the isolation boundary. |
| BR-TEN-002 | An organization contains at least one school. Deleting the last school of an active organization is rejected. |
| BR-TEN-003 | A school belongs to exactly one organization and cannot be moved between organizations. |
| BR-TEN-004 | 🔴 No request may read or write data belonging to an organization other than the one in its authenticated context, except through an explicitly permissioned platform-operations path, which is always audited. |
| BR-TEN-005 | Branches are optional. A null branch on a school-scoped record means "school-wide" and is valid. |
| BR-TEN-006 | Suspending an organization blocks all user access except platform operations, but destroys no data and stops no in-flight safety recording for trips already started. |
| BR-TEN-007 | Organization and school codes are unique within their parent scope and immutable once operational data exists. |

---

## BR-IAM — Identity & Access

| ID | Rule |
|---|---|
| BR-IAM-001 | 🔴 Authorisation is decided server-side on every request. A client-supplied role, scope, or permission claim is never trusted. |
| BR-IAM-002 | 🔴 Access is deny-by-default. An endpoint with no declared permission is inaccessible. |
| BR-IAM-003 | A user has one or more roles within a single organization. Cross-organization users are not permitted except platform operators. |
| BR-IAM-004 | Permissions are resolved per request from current role assignments, not from the access token. A permission change takes effect on the next request. |
| BR-IAM-005 | 🔴 A guardian may access data for students they are actively linked to, and no others. |
| BR-IAM-006 | Staff access is scoped to their assigned school; transport staff are further scoped to their assigned routes or current trip. |
| BR-IAM-007 | Revoking a session invalidates its refresh token immediately, and its access token within the denylist propagation window (≤15 minutes, per ADR-0006). |
| BR-IAM-008 | Deactivating a staff member revokes all their sessions immediately and removes them from future duty assignments. |
| BR-IAM-009 | Refresh tokens are single-use. Reuse of a consumed refresh token invalidates the entire session family and raises a security alert. |
| BR-IAM-010 | A person may hold both guardian and staff roles. Their guardian rights over their own child are independent of their staff scope. |
| BR-IAM-011 | Failed authentication attempts are rate-limited per identifier and per source. Lockout thresholds are tenant configuration with a platform-enforced floor. |
| BR-IAM-012 | 🔴 Every access to child personal data by a non-guardian user is recorded as a data-access audit event. |

---

## BR-STU — Student Registry

| ID | Rule |
|---|---|
| BR-STU-001 | A student belongs to exactly one school at a time. |
| BR-STU-002 | A student must have at least one active guardian relationship before they can be assigned to a route. |
| BR-STU-003 | A student's admission number is unique within their school. |
| BR-STU-004 | Only students with an active enrolment status may be assigned to routes or appear on a manifest. |
| BR-STU-005 | Student records are never hard-deleted while any safety record references them. Withdrawal sets enrolment status and removes future route assignments. |
| BR-STU-006 | Changing a student's school clears all route assignments in the previous school. |

---

## BR-GRD — Guardian Management

| ID | Rule |
|---|---|
| BR-GRD-001 | A guardian–student relationship carries an explicit rights set: view, receive notifications, authorise handover, declare absence. Rights are not implied by relationship type. |
| BR-GRD-002 | 🔴 At least one guardian per student must hold the "authorise handover" right. |
| BR-GRD-003 | A student may have multiple guardians; each has independent notification preferences. |
| BR-GRD-004 | Deactivating a guardian relationship immediately removes that guardian's access to the student and stops their notifications. |
| BR-GRD-005 | An authorised pickup person is valid only within their configured validity window and only for the students they are explicitly listed against. |
| BR-GRD-006 | 🔴 An authorised pickup person may be nominated only by a guardian holding the "authorise handover" right, and the nomination is audited. |
| BR-GRD-007 | Authorised pickup person nominations may be revoked at any time by any guardian holding the "authorise handover" right, taking effect immediately. |
| BR-GRD-008 | Where a custody restriction is recorded against a guardian, that guardian is blocked from handover and from location visibility, regardless of relationship type. |

---

## BR-FLEET — Fleet

| ID | Rule |
|---|---|
| BR-FLEET-001 | A vehicle belongs to one school and has a registration number unique within its organization. |
| BR-FLEET-002 | 🔴 A vehicle with an expired mandatory document may not be assigned to a trip. Which documents are mandatory is region configuration (ADR-0007); that a mandatory expired document blocks assignment is not configurable. |
| BR-FLEET-003 | Vehicle document expiry generates escalating advance warnings at configured intervals. |
| BR-FLEET-004 | A vehicle has at most one active GPS device at a time. |
| BR-FLEET-005 | A vehicle's seating capacity is recorded; assigning students beyond capacity to a single trip raises a warning and requires an audited override. |
| BR-FLEET-006 | A device reporting positions for an unassigned or unknown vehicle is logged and ignored, never auto-registered. |

---

## BR-STAFF — Transport Staff

| ID | Rule |
|---|---|
| BR-STAFF-001 | 🔴 A driver may not be assigned to a trip without a valid, unexpired licence of the required class. |
| BR-STAFF-002 | 🔴 A driver or attendant may not be assigned to a trip if their verification status is not "verified" or has lapsed. Required verification types are region configuration. |
| BR-STAFF-003 | Staff credential expiry generates escalating advance warnings and blocks future duty assignment on expiry. |
| BR-STAFF-004 | A staff member may be assigned to at most one active trip at a time. |
| BR-STAFF-005 | Whether an attendant is mandatory for a trip is tenant configuration; where mandatory, a trip cannot start without one. |
| BR-STAFF-006 | A substitute driver may be assigned to an in-progress trip; the change is recorded with both staff members and the time of handover. |

---

## BR-ROUTE — Routes & Stops

| ID | Rule |
|---|---|
| BR-ROUTE-001 | A route has at least two stops and belongs to one school. |
| BR-ROUTE-002 | Stops are ordered; the order defines sequence and expected arrival times. |
| BR-ROUTE-003 | Each stop has coordinates and a geofence radius. The radius has a configurable default and a platform-enforced minimum and maximum. |
| BR-ROUTE-004 | A student is assigned to at most one pickup stop and one drop stop per route direction. Pickup and drop stops may differ. |
| BR-ROUTE-005 | A student may hold assignments on different routes for pickup and drop. |
| BR-ROUTE-006 | Changing a route or its stops does not alter trips already started; changes apply to trips generated after the change. |
| BR-ROUTE-007 | Deactivating a route requires reassigning or explicitly releasing every student assigned to it. |
| BR-ROUTE-008 | Scheduled stop times must be strictly increasing along the route sequence for a direction. |

---

## BR-TRIP — Trip Execution

| ID | Rule |
|---|---|
| BR-TRIP-001 | A trip is one execution of one route, on one date, in one direction. |
| BR-TRIP-002 | Trip status transitions are `SCHEDULED → STARTED → IN_PROGRESS → COMPLETED → CLOSED`, with `CANCELLED` reachable from `SCHEDULED` or `STARTED`. No other transition is valid. |
| BR-TRIP-003 | 🔴 The manifest is materialised at trip start from route assignments minus declared absences, and is thereafter immutable. Late changes are recorded as manifest amendments with actor and reason, never as silent edits. |
| BR-TRIP-004 | A trip may not start without an assigned vehicle and driver satisfying BR-FLEET-002, BR-STAFF-001, and BR-STAFF-002. |
| BR-TRIP-005 | A trip may not start if another active trip exists for the same vehicle or the same driver. |
| BR-TRIP-006 | Only the assigned driver, assigned attendant, or a transport manager may start or end a trip. |
| BR-TRIP-007 | A cancelled trip notifies all affected guardians with the reason. |
| BR-TRIP-008 | Trip start and end times are recorded from the server; device-reported times are stored alongside for reference (ADR-0008). |
| BR-TRIP-009 | 🔴 A trip cannot move to `CLOSED` until reconciliation completes — see BR-SAFE-001. |
| BR-TRIP-010 | A trip not started within a configurable window after its scheduled time raises a delay alert to the transport manager and to affected guardians. |
| BR-TRIP-011 | Trips are generated in advance for scheduled operating days; school holidays and non-operating days suppress generation. |

---

## BR-BOARD — Boarding & Attendance

| ID | Rule |
|---|---|
| BR-BOARD-001 | 🔴 Boarding records are append-only. A record is never updated or deleted; a correction is a new compensating record referencing the original, with actor and reason. |
| BR-BOARD-002 | Every boarding event records: student, trip, type (`BOARD`/`ALIGHT`), actor, verification method, device position, `occurred_at`, and `recorded_at`. |
| BR-BOARD-003 | A student may not be recorded as boarded on a trip where they are not on the manifest, without an audited override by an authorised actor. |
| BR-BOARD-004 | 🔴 A student may not be marked as alighted at a stop other than their assigned stop for that direction without an audited override, and the override notifies their guardians immediately. |
| BR-BOARD-005 | A student cannot board twice on the same trip without an intervening alight. |
| BR-BOARD-006 | A student cannot alight on a trip they did not board. |
| BR-BOARD-007 | A student marked absent for a trip who then boards generates an alert and removes the absence, recording both facts. |
| BR-BOARD-008 | Boarding events created offline retain their `occurred_at` from the device with a recorded clock-skew estimate, and are ordered by `occurred_at` for reporting (ADR-0008). |
| BR-BOARD-009 | Duplicate submissions of the same client event ID are idempotent and create exactly one record. |
| BR-BOARD-010 | Every boarding and alighting event notifies the student's guardians who hold the notification right. |

---

## BR-HAND — Guardian Handover

| ID | Rule |
|---|---|
| BR-HAND-001 | 🔴 On a `DROP` trip, a student is released only to a guardian holding the "authorise handover" right, or to a valid authorised pickup person, or by an audited override. Handover verification cannot be disabled by configuration. |
| BR-HAND-002 | Acceptable verification methods (QR, OTP, PIN, attendant visual confirmation) are tenant configuration; at least one method must be enabled. |
| BR-HAND-003 | 🔴 A handover override — releasing a student to an unverified adult — requires a reason, is permitted only to an authorised actor, is recorded with the receiver's recorded identity, and immediately notifies all guardians and the transport manager. |
| BR-HAND-004 | A handover record references the boarding event's alight record; a handover cannot exist without one. |
| BR-HAND-005 | Where a student is authorised for self-release (age or policy based, per tenant configuration), the handover records self-release as the method and notifies guardians. |
| BR-HAND-006 | 🔴 A guardian recorded with a custody restriction (BR-GRD-008) is refused handover, and the attempt is recorded and escalated to the transport manager. |
| BR-HAND-007 | If no authorised receiver is present at the stop, the student remains on the vehicle, an exception is raised, and the escalation chain in tenant configuration is followed. The student is never released to no one. |

---

## BR-SAFE — Safety Controls

All rules in this section are safety-critical.

| ID | Rule |
|---|---|
| BR-SAFE-001 | 🔴 **Left-behind detection.** At trip completion, every student with a `BOARD` event and no corresponding `ALIGHT` event is an unaccounted child. This raises a critical alert to the driver, attendant, transport manager, and the student's guardians within the configured detection window, and blocks trip closure until each case is resolved with an explicit outcome and actor. |
| BR-SAFE-002 | 🔴 **No-show handling.** A student on the manifest with no `BOARD` event by the time the vehicle departs their stop is recorded as a no-show and their guardians are notified. |
| BR-SAFE-003 | 🔴 **Wrong-vehicle detection.** A student scanned onto a trip whose manifest does not include them, where they are on another active trip's manifest for the same date and direction, raises an immediate alert to both trips' staff and to the student's guardians. |
| BR-SAFE-004 | 🔴 An SOS alert is delivered to the escalation chain regardless of quiet hours, notification preferences, or channel opt-outs. |
| BR-SAFE-005 | 🔴 Safety events recorded offline are never discarded. If they conflict with server state, they are accepted and flagged for review (ADR-0008). |
| BR-SAFE-006 | 🔴 A safety alert that is not acknowledged within its configured window escalates to the next level of the chain, repeatedly, until acknowledged. |
| BR-SAFE-007 | 🔴 Configuration may tighten a safety threshold but never loosen it beyond the platform-enforced floor. |

---

## BR-TRACK — Tracking

| ID | Rule |
|---|---|
| BR-TRACK-001 | Vehicle position is recorded and visible only while a trip is active. Vehicles are not tracked outside trip windows. |
| BR-TRACK-002 | Live position visible to a guardian is limited to trips carrying one of their students. |
| BR-TRACK-003 | Positions older than the configured staleness threshold are shown as stale, never as current. |
| BR-TRACK-004 | A position report with implausible coordinates, speed, or timestamp is rejected and logged, not stored as fact. |
| BR-TRACK-005 | Loss of position reporting for longer than the configured threshold during an active trip raises an alert to the transport manager. |
| BR-TRACK-006 | ETA is an estimate and is always presented as such, with its calculation time. |
| BR-TRACK-007 | Position history retention is tenant configuration, bounded by a platform minimum sufficient for incident investigation. |

---

## BR-ALERT — Geofencing & Alerts

| ID | Rule |
|---|---|
| BR-ALERT-001 | Stop arrival is detected by geofence entry and generates approach and arrival notifications per configuration. |
| BR-ALERT-002 | Route deviation is raised when a vehicle exceeds the configured corridor distance from its route path for longer than the configured duration. |
| BR-ALERT-003 | Overspeed is raised when speed exceeds the configured limit for longer than the configured duration. The limit is tenant configuration with a platform-enforced maximum. |
| BR-ALERT-004 | An unscheduled stop — stationary beyond a threshold outside a defined stop — raises an alert to the transport manager. |
| BR-ALERT-005 | Alerts are deduplicated: a continuing condition produces one open alert, not a stream. |
| BR-ALERT-006 | Every alert has a severity, an owner, and a resolution state. Alerts are not silently dropped. |

---

## BR-NTF — Notification

| ID | Rule |
|---|---|
| BR-NTF-001 | Notification recipients are resolved from explicit rights, never inferred from proximity or role alone. |
| BR-NTF-002 | Each notification event has a defined template per channel and locale; a missing template falls back to the tenant default locale and logs a gap. |
| BR-NTF-003 | Guardians set per-event, per-channel preferences. |
| BR-NTF-004 | Quiet hours suppress non-urgent notifications, deferring rather than discarding them. |
| BR-NTF-005 | Delivery is attempted with retry and backoff; every attempt and outcome is recorded. |
| BR-NTF-006 | 🔴 Safety-critical notifications ignore preferences, quiet hours, and channel opt-outs, and escalate to a fallback channel on primary-channel failure. |
| BR-NTF-007 | 🔴 A notification never contains another family's child's name or personal data. |
| BR-NTF-008 | Notification content is rendered from templates only; no user-supplied content is sent unescaped. |

---

## BR-INC — Incident & Emergency

| ID | Rule |
|---|---|
| BR-INC-001 | 🔴 An SOS is delivered within the configured target, and its escalation chain runs until acknowledged (BR-SAFE-006). |
| BR-INC-002 | An SOS records the raising actor, trip, vehicle position, and time. It cannot be deleted; it is resolved with an outcome. |
| BR-INC-003 | Incidents have a severity that determines the notification audience and escalation chain. |
| BR-INC-004 | An incident affecting a specific student notifies that student's guardians; an incident affecting a trip notifies all guardians on that trip's manifest, without disclosing other students' identities (BR-NTF-007). |
| BR-INC-005 | Every incident has a resolution recorded with actor, outcome, and time before it can be closed. |
| BR-INC-006 | A false-alarm SOS is resolved as such, not deleted, so that patterns remain visible. |

---

## BR-ABS — Absence

| ID | Rule |
|---|---|
| BR-ABS-001 | A guardian holding the "declare absence" right may declare a student absent for a trip, a date, or a date range. |
| BR-ABS-002 | An absence declared before trip start removes the student from the materialised manifest (BR-TRIP-003). |
| BR-ABS-003 | An absence declared after trip start does not alter the manifest; it is recorded as a manifest amendment and notified to the trip staff. |
| BR-ABS-004 | An absence may be cancelled by a guardian until the trip starts. |
| BR-ABS-005 | A declared absence suppresses no-show alerts (BR-SAFE-002) for that student and trip. |

---

## BR-AUD — Audit

| ID | Rule |
|---|---|
| BR-AUD-001 | 🔴 Audit records are append-only. No path exists to update or delete one within the retention period. |
| BR-AUD-002 | 🔴 The audit write participates in the same transaction as the change it records. If the audit write fails, the change is rolled back. |
| BR-AUD-003 | Every audit record captures actor, action, subject, timestamp, source, tenant, and reason where the action requires one. |
| BR-AUD-004 | Every override records a reason. An override without a reason is rejected. |
| BR-AUD-005 | Platform-operator actions crossing organization boundaries are always audited (BR-TEN-004). |
| BR-AUD-006 | Audit records contain no credentials, tokens, or unnecessary child personal data. |
| BR-AUD-007 | Audit retention meets or exceeds the longest applicable legal requirement for the tenant's region. |

---

## BR-CFG — Configuration

| ID | Rule |
|---|---|
| BR-CFG-001 | Every configuration key declares a type, default, permitted range, and the scope level at which it may be set. |
| BR-CFG-002 | Configuration resolves in order: school → organization → region profile → platform default. |
| BR-CFG-003 | 🔴 Safety-critical configuration values are bounded by platform-enforced floors and ceilings that a tenant cannot exceed (BR-SAFE-007). |
| BR-CFG-004 | Every configuration change is audited with actor, old value, new value, and time. |
| BR-CFG-005 | No user-facing text is hardcoded; all such text is a localised resource key (ADR-0007). |
| BR-CFG-006 | Times are stored in UTC and displayed in the school's configured time zone. |

---

## BR-RPT — Reporting

| ID | Rule |
|---|---|
| BR-RPT-001 | Reports respect the requesting user's scope. A report never reveals data the user could not read directly. |
| BR-RPT-002 | 🔴 Every export of child personal data is permission-gated and audited, recording actor, scope, and record count. |
| BR-RPT-003 | Reports state the time zone and generation time of the data they present. |
| BR-RPT-004 | Reporting queries never block operational writes. |

---

## Change Control

Adding a rule: append with the next ID in its area; never reuse or renumber an ID. Add a test referencing the ID.

Changing or removing a 🔴 rule requires an ADR stating what replaces the control it provided.

Superseded rules are marked `**Superseded by BR-xxx-nnn**` and retained — history matters in a safety system.
