# FEATURE INVENTORY

**Document tier:** 1 — Product Discovery
**Priority:** 6
**Status:** Active

The canonical list of features. **Feature IDs are the traceability key** across API, UI, and test documents ([`DOCUMENT_HIERARCHY.md`](../00-governance/DOCUMENT_HIERARCHY.md)).

**Release column:** `R1` = first production release · `R2` = second · `L` = later, documented so the design accommodates it.

---

## TEN — Tenancy (MOD-01)

| ID | Feature | Rules | Release |
|---|---|---|---|
| TEN-001 | Create and onboard an organization | BR-TEN-001, BR-TEN-002 | R1 |
| TEN-002 | Manage schools within an organization | BR-TEN-003, BR-TEN-007 | R1 |
| TEN-003 | Manage branches within a school | BR-TEN-005 | R2 |
| TEN-004 | Suspend and reactivate an organization | BR-TEN-006 | R1 |
| TEN-005 | School operating calendar and timings | BR-TRIP-011, BR-CFG-006 | R1 |

## IAM — Identity & Access (MOD-02)

| ID | Feature | Rules | Release |
|---|---|---|---|
| IAM-001 | Staff login with password | BR-IAM-001, BR-IAM-011 | R1 |
| IAM-002 | Guardian login (phone + OTP) | BR-IAM-001, BR-IAM-011 | R1 |
| IAM-003 | Token refresh with rotation and reuse detection | BR-IAM-007, BR-IAM-009 | R1 |
| IAM-004 | Session listing and revocation | BR-IAM-007 | R1 |
| IAM-005 | Role management | BR-IAM-003, BR-IAM-004 | R1 |
| IAM-006 | Permission assignment to roles | BR-IAM-002, BR-IAM-004 | R1 |
| IAM-007 | Scope resolution (org / school / route / own-children) | BR-IAM-005, BR-IAM-006 | R1 |
| IAM-008 | Staff deactivation with session revocation | BR-IAM-008 | R1 |
| IAM-009 | Password reset | BR-IAM-011 | R1 |
| IAM-010 | Data-access logging for child PII | BR-IAM-012 | R1 |
| IAM-011 | School SSO for staff | — *needs ADR* | L |

## STU — Student Registry (MOD-03)

| ID | Feature | Rules | Release |
|---|---|---|---|
| STU-001 | Create and edit a student record | BR-STU-001, BR-STU-003 | R1 |
| STU-002 | Bulk import students | BR-STU-001, BR-STU-003 | R1 |
| STU-003 | Class and section management | — | R1 |
| STU-004 | Enrolment status lifecycle | BR-STU-004, BR-STU-005 | R1 |
| STU-005 | Transfer a student between schools | BR-STU-006 | R2 |
| STU-006 | Student photo for handover identification | BR-HAND-001 | R1 |
| STU-007 | Student boarding credential (QR / card) | BR-BOARD-002 | R1 |

## GRD — Guardian Management (MOD-04)

| ID | Feature | Rules | Release |
|---|---|---|---|
| GRD-001 | Create a guardian and link to a student with rights | BR-GRD-001, BR-GRD-002 | R1 |
| GRD-002 | Manage multiple guardians per student | BR-GRD-003 | R1 |
| GRD-003 | Deactivate a guardian relationship | BR-GRD-004 | R1 |
| GRD-004 | Nominate an authorised pickup person | BR-GRD-005, BR-GRD-006 | R1 |
| GRD-005 | Revoke an authorised pickup person | BR-GRD-007 | R1 |
| GRD-006 | Record a custody restriction | BR-GRD-008, BR-HAND-006 | R2 |
| GRD-007 | Guardian self-service profile and preferences | BR-NTF-003 | R1 |

## FLT — Fleet (MOD-05)

| ID | Feature | Rules | Release |
|---|---|---|---|
| FLT-001 | Register and manage vehicles | BR-FLEET-001, BR-FLEET-005 | R1 |
| FLT-002 | Vehicle document register with expiry | BR-FLEET-002, BR-FLEET-003 | R1 |
| FLT-003 | Document expiry warnings and blocking | BR-FLEET-002, BR-FLEET-003 | R1 |
| FLT-004 | Register and assign GPS devices | BR-FLEET-004, BR-FLEET-006 | R1 |
| FLT-005 | Vehicle capacity enforcement | BR-FLEET-005 | R1 |

## STF — Transport Staff (MOD-06)

| ID | Feature | Rules | Release |
|---|---|---|---|
| STF-001 | Create driver and attendant records | BR-STAFF-001 | R1 |
| STF-002 | Credential register with expiry | BR-STAFF-001, BR-STAFF-003 | R1 |
| STF-003 | Verification status tracking | BR-STAFF-002 | R1 |
| STF-004 | Duty assignment to routes | BR-STAFF-004, BR-STAFF-005 | R1 |
| STF-005 | Substitute staff assignment mid-trip | BR-STAFF-006 | R2 |
| STF-006 | Vendor-scoped staff access | BR-IAM-006 | R2 |

## RTE — Routes & Stops (MOD-07)

| ID | Feature | Rules | Release |
|---|---|---|---|
| RTE-001 | Define a route with ordered stops | BR-ROUTE-001, BR-ROUTE-002, BR-ROUTE-008 | R1 |
| RTE-002 | Configure stop geofence radius | BR-ROUTE-003 | R1 |
| RTE-003 | Assign students to stops per direction | BR-ROUTE-004, BR-ROUTE-005 | R1 |
| RTE-004 | Bulk student-to-route assignment | BR-ROUTE-004 | R1 |
| RTE-005 | Route map editing | BR-ROUTE-002 | R2 |
| RTE-006 | Deactivate a route with reassignment | BR-ROUTE-007 | R1 |
| RTE-007 | Route optimisation suggestions | — | L |

## TRP — Trip Execution (MOD-08)

| ID | Feature | Rules | Release |
|---|---|---|---|
| TRP-001 | Generate scheduled trips for operating days | BR-TRIP-011 | R1 |
| TRP-002 | Start a trip with eligibility checks | BR-TRIP-004, BR-TRIP-005, BR-TRIP-006 | R1 |
| TRP-003 | Materialise the trip manifest | BR-TRIP-003, BR-ABS-002 | R1 |
| TRP-004 | Trip lifecycle transitions | BR-TRIP-002 | R1 |
| TRP-005 | Cancel a trip with guardian notification | BR-TRIP-007 | R1 |
| TRP-006 | Manifest amendment with reason | BR-TRIP-003, BR-ABS-003 | R1 |
| TRP-007 | Trip delay detection and alerting | BR-TRIP-010 | R1 |
| TRP-008 | Trip close with reconciliation gate | BR-TRIP-009, BR-SAFE-001 | R1 |

## BRD — Boarding & Attendance (MOD-09)

| ID | Feature | Rules | Release |
|---|---|---|---|
| BRD-001 | Record boarding by credential scan | BR-BOARD-002, BR-BOARD-009 | R1 |
| BRD-002 | Record boarding manually from the manifest | BR-BOARD-002, BR-BOARD-003 | R1 |
| BRD-003 | Record alighting | BR-BOARD-004, BR-BOARD-006 | R1 |
| BRD-004 | Offline recording with deferred sync | BR-BOARD-008, BR-SAFE-005 | R1 |
| BRD-005 | Compensating correction records | BR-BOARD-001 | R1 |
| BRD-006 | Off-manifest boarding override | BR-BOARD-003 | R1 |
| BRD-007 | Wrong-stop alight override with notification | BR-BOARD-004 | R1 |
| BRD-008 | Guardian handover verification | BR-HAND-001, BR-HAND-002 | R1 |
| BRD-009 | Handover to authorised pickup person | BR-GRD-005, BR-HAND-001 | R1 |
| BRD-010 | Handover override with escalation | BR-HAND-003 | R1 |
| BRD-011 | Student self-release | BR-HAND-005 | R2 |
| BRD-012 | No-receiver exception handling | BR-HAND-007 | R1 |
| BRD-013 | Trip-close reconciliation | BR-SAFE-001 | R1 |
| BRD-014 | Left-behind critical alert | BR-SAFE-001 | R1 |
| BRD-015 | No-show detection | BR-SAFE-002 | R1 |
| BRD-016 | Wrong-vehicle detection | BR-SAFE-003 | R1 |

## TRK — Tracking (MOD-10)

| ID | Feature | Rules | Release |
|---|---|---|---|
| TRK-001 | Ingest device position reports | BR-TRACK-004, BR-FLEET-006 | R1 |
| TRK-002 | Live vehicle position for authorised viewers | BR-TRACK-001, BR-TRACK-002 | R1 |
| TRK-003 | Live trip tracking in the parent app | BR-TRACK-002, BR-TRACK-003 | R1 |
| TRK-004 | Fleet live map for managers | BR-TRACK-001 | R1 |
| TRK-005 | Stop ETA calculation | BR-TRACK-006 | R1 |
| TRK-006 | Position history and trip replay | BR-TRACK-007 | R1 |
| TRK-007 | Signal-loss alerting | BR-TRACK-005 | R1 |
| TRK-008 | Device adapter for a new vendor protocol | ADR-0004 | R1 |

## ALT — Geofencing & Alerts (MOD-11)

| ID | Feature | Rules | Release |
|---|---|---|---|
| ALT-001 | Stop geofence arrival detection | BR-ALERT-001 | R1 |
| ALT-002 | Approaching-stop notification | BR-ALERT-001 | R1 |
| ALT-003 | School arrival and departure detection | BR-ALERT-001 | R1 |
| ALT-004 | Route deviation detection | BR-ALERT-002 | R1 |
| ALT-005 | Overspeed detection | BR-ALERT-003 | R1 |
| ALT-006 | Unscheduled stop detection | BR-ALERT-004 | R2 |
| ALT-007 | Alert deduplication and lifecycle | BR-ALERT-005, BR-ALERT-006 | R1 |

## NTF — Notification (MOD-12)

| ID | Feature | Rules | Release |
|---|---|---|---|
| NTF-001 | Recipient resolution from rights | BR-NTF-001, BR-NTF-007 | R1 |
| NTF-002 | Template management per tenant and locale | BR-NTF-002, BR-CFG-005 | R1 |
| NTF-003 | Push delivery | BR-NTF-005 | R1 |
| NTF-004 | SMS delivery via configurable provider | BR-NTF-005, ADR-0005 | R1 |
| NTF-005 | Email delivery | BR-NTF-005 | R2 |
| NTF-006 | In-app notification centre | BR-NTF-005 | R1 |
| NTF-007 | Guardian notification preferences | BR-NTF-003, BR-NTF-004 | R1 |
| NTF-008 | Safety-critical override of preferences | BR-NTF-006, BR-SAFE-004 | R1 |
| NTF-009 | Delivery records and failure visibility | BR-NTF-005 | R1 |

## INC — Incident & Emergency (MOD-13)

| ID | Feature | Rules | Release |
|---|---|---|---|
| INC-001 | Raise SOS from the driver app | BR-INC-001, BR-INC-002 | R1 |
| INC-002 | SOS escalation chain until acknowledged | BR-SAFE-006, BR-INC-001 | R1 |
| INC-003 | SOS acknowledgement and resolution | BR-INC-005, BR-INC-006 | R1 |
| INC-004 | Report an incident with severity | BR-INC-003 | R1 |
| INC-005 | Incident notification audience by severity | BR-INC-004, BR-NTF-007 | R1 |
| INC-006 | Incident resolution and closure | BR-INC-005 | R1 |
| INC-007 | Device-triggered panic button | BR-INC-001 | R2 |

## ABS — Absence (MOD-14)

| ID | Feature | Rules | Release |
|---|---|---|---|
| ABS-001 | Declare absence for a trip or date | BR-ABS-001, BR-ABS-002 | R1 |
| ABS-002 | Declare absence for a date range | BR-ABS-001 | R1 |
| ABS-003 | Cancel a declared absence | BR-ABS-004 | R1 |
| ABS-004 | Late absence as manifest amendment | BR-ABS-003 | R1 |
| ABS-005 | Absence suppresses no-show alerts | BR-ABS-005 | R1 |

## RPT — Reporting (MOD-15)

| ID | Feature | Rules | Release |
|---|---|---|---|
| RPT-001 | Daily trip operations report | BR-RPT-001, BR-RPT-003 | R1 |
| RPT-002 | Student attendance report | BR-RPT-001 | R1 |
| RPT-003 | Safety exception report | BR-SAFE-001, BR-RPT-001 | R1 |
| RPT-004 | Vehicle and staff compliance report | BR-FLEET-002, BR-STAFF-003 | R1 |
| RPT-005 | Incident summary report | BR-INC-003 | R2 |
| RPT-006 | Audited data export | BR-RPT-002 | R1 |
| RPT-007 | Management dashboard | BR-RPT-001 | R2 |

## AUD — Audit (MOD-16)

| ID | Feature | Rules | Release |
|---|---|---|---|
| AUD-001 | Transactional audit record writing | BR-AUD-001, BR-AUD-002 | R1 |
| AUD-002 | Audit trail search | BR-AUD-003 | R1 |
| AUD-003 | Override register with reasons | BR-AUD-004 | R1 |
| AUD-004 | Cross-tenant operation audit | BR-TEN-004, BR-AUD-005 | R1 |
| AUD-005 | Retention enforcement | BR-AUD-007 | R2 |

## CFG — Configuration (MOD-17)

| ID | Feature | Rules | Release |
|---|---|---|---|
| CFG-001 | Typed configuration registry | BR-CFG-001 | R1 |
| CFG-002 | Scoped configuration resolution | BR-CFG-002 | R1 |
| CFG-003 | Region profiles | ADR-0007 | R1 |
| CFG-004 | Safety floors and ceilings | BR-CFG-003, BR-SAFE-007 | R1 |
| CFG-005 | Configuration change audit | BR-CFG-004 | R1 |
| CFG-006 | Localisation resources | BR-CFG-005 | R1 |
| CFG-007 | School time zone handling | BR-CFG-006 | R1 |

---

## Adding a Feature

1. Append with the next ID in its area. Never reuse an ID.
2. List the business rules it implements — if none exist, write the rule first.
3. Reference the ID in the API document, the UI document, and its test cases.

A feature in code but not in this inventory is untracked work and fails review.
