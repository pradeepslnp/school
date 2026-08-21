# SCREEN INVENTORY

**Document tier:** 5 — UI
**Status:** Active

Every screen across the three clients, with its feature IDs and the permission that gates it.

---

## Parent App — `flutter/parent_app`

| ID | Screen | Features | Permission |
|---|---|---|---|
| P-01 | Login (phone + OTP) | IAM-002 | public |
| P-02 | **Home — children status** | TRK-003, BRD-001 | authenticated |
| P-03 | Child detail | STU-001, BRD-003 | `OWN_CHILDREN` |
| P-04 | Live trip map | TRK-003, TRK-005 | `PERM-TRACKING-LIVE-VIEW` |
| P-05 | Journey history | BRD-003, TRK-006 | `PERM-BOARDING-VIEW` |
| P-06 | Declare absence | ABS-001, ABS-002 | `PERM-ABSENCE-DECLARE` |
| P-07 | Authorised pickup persons | GRD-004, GRD-005 | `PERM-PICKUP-PERSON-MANAGE` |
| P-08 | Notification centre | NTF-006 | authenticated |
| P-09 | Notification preferences | NTF-007 | `PERM-NOTIFICATION-PREFERENCE-SELF` |
| P-10 | Profile & language | GRD-007 | `PERM-PROFILE-SELF-EDIT` |
| P-11 | Incident detail | INC-005 | `PERM-INCIDENT-VIEW` |
| P-12 | Handover verification (QR/OTP) | BRD-008 | `OWN_CHILDREN` |

**P-02 is the product.** It answers "is my child fine?" without a tap. Everything else is secondary.

---

## Driver & Attendant App — `flutter/driver_attender_app`

| ID | Screen | Features | Permission |
|---|---|---|---|
| D-01 | Login | IAM-001 | public |
| D-02 | Today's trips | TRP-004 | `PERM-TRIP-VIEW` |
| D-03 | Pre-trip eligibility check | TRP-002, FLT-003, STF-003 | `PERM-TRIP-START` |
| D-04 | **Active trip — next stop** | TRP-004, TRK-001 | `PERM-TRIP-VIEW` |
| D-05 | **Stop boarding (scan)** | BRD-001, BRD-002 | `PERM-BOARDING-RECORD` |
| D-06 | Manifest list | TRP-003 | `PERM-TRIP-VIEW` |
| D-07 | Alighting at stop | BRD-003 | `PERM-BOARDING-RECORD` |
| D-08 | **Handover verification** | BRD-008, BRD-009 | `PERM-HANDOVER-RECORD` |
| D-09 | Handover override | BRD-010 | `PERM-HANDOVER-OVERRIDE` |
| D-10 | No-receiver exception | BRD-012 | `PERM-HANDOVER-RECORD` |
| D-11 | Trip end & reconciliation | TRP-008, BRD-013 | `PERM-TRIP-END` |
| D-12 | Reconciliation resolution | BRD-013 | `PERM-RECONCILIATION-RESOLVE` |
| D-13 | Report incident | INC-004 | `PERM-INCIDENT-CREATE` |
| D-14 | Sync status | BRD-004 | authenticated |
| D-15 | **SOS** (overlay, every screen) | INC-001 | `PERM-SOS-RAISE` |

**D-15 is present on every screen** and reachable in one action without looking (ADR-0008 context: the app is operated near a moving vehicle).

**D-14 is not optional.** Silent offline queuing hides failure from the person who most needs to know ([`PERSONAS.md`](../01-product-discovery/PERSONAS.md), Sunita).

---

## Admin Web — `admin`

### Dashboard & Operations

| ID | Screen | Features | Permission |
|---|---|---|---|
| A-01 | Operations dashboard | RPT-007, ALT-007 | `PERM-REPORT-OPERATIONAL` |
| A-02 | Fleet live map | TRK-004 | `PERM-TRACKING-LIVE-VIEW` |
| A-03 | Active trips monitor | TRP-004 | `PERM-TRIP-VIEW` |
| A-04 | Alert inbox | ALT-007 | `PERM-ALERT-VIEW` |
| A-05 | SOS & incident console | INC-002, INC-003 | `PERM-SOS-ACKNOWLEDGE` |
| A-06 | Safety exceptions | BRD-014, RPT-003 | `PERM-REPORT-SAFETY` |

### Students & Guardians

| ID | Screen | Features | Permission |
|---|---|---|---|
| A-10 | Student register | STU-001 | `PERM-STUDENT-VIEW` |
| A-11 | Student detail | STU-001, STU-006, STU-007 | `PERM-STUDENT-VIEW` |
| A-12 | Bulk student import | STU-002 | `PERM-STUDENT-IMPORT` |
| A-13 | Guardian links & rights | GRD-001, GRD-002, GRD-003 | `PERM-GUARDIAN-LINK` |
| A-14 | Custody restrictions | GRD-006 | `PERM-CUSTODY-RESTRICTION-MANAGE` |
| A-15 | Classes | STU-003 | `PERM-STUDENT-EDIT` |

### Fleet & Staff

| ID | Screen | Features | Permission |
|---|---|---|---|
| A-20 | Vehicle register | FLT-001 | `PERM-VEHICLE-VIEW` |
| A-21 | Vehicle documents & expiry | FLT-002, FLT-003 | `PERM-VEHICLE-DOCUMENT-MANAGE` |
| A-22 | Device assignment | FLT-004 | `PERM-DEVICE-MANAGE` |
| A-23 | Staff register | STF-001 | `PERM-STAFF-MANAGE` |
| A-24 | Staff credentials & verification | STF-002, STF-003 | `PERM-STAFF-VERIFY` |
| A-25 | Duty assignments | STF-004 | `PERM-DUTY-ASSIGN` |
| A-26 | Compliance overview | RPT-004 | `PERM-REPORT-COMPLIANCE` |

### Routes & Trips

| ID | Screen | Features | Permission |
|---|---|---|---|
| A-30 | Route list | RTE-001 | `PERM-ROUTE-VIEW` |
| A-31 | Route editor (map) | RTE-001, RTE-002, RTE-005 | `PERM-ROUTE-MANAGE` |
| A-32 | Student route assignment | RTE-003, RTE-004 | `PERM-ROUTE-ASSIGN-STUDENT` |
| A-33 | Trip schedule | TRP-001 | `PERM-TRIP-VIEW` |
| A-34 | Trip detail & manifest | TRP-003, TRP-006 | `PERM-TRIP-VIEW` |
| A-35 | Trip replay | TRK-006 | `PERM-TRACKING-HISTORY-VIEW` |

### Administration

| ID | Screen | Features | Permission |
|---|---|---|---|
| A-40 | Organizations | TEN-001, TEN-004 | `PERM-ORG-VIEW` |
| A-41 | Schools | TEN-002 | `PERM-SCHOOL-VIEW` |
| A-42 | School calendar | TEN-005 | `PERM-SCHOOL-EDIT` |
| A-43 | Users | IAM-005, IAM-008 | `PERM-USER-VIEW` |
| A-44 | Roles & permissions | IAM-005, IAM-006 | `PERM-ROLE-MANAGE` |
| A-45 | Configuration | CFG-001, CFG-002 | `PERM-CONFIG-VIEW` |
| A-46 | Notification templates | NTF-002 | `PERM-NOTIFICATION-TEMPLATE-MANAGE` |
| A-47 | Alert rules | ALT-004…006 | `PERM-CONFIG-EDIT` |

### Reporting & Audit

| ID | Screen | Features | Permission |
|---|---|---|---|
| A-50 | Trip operations report | RPT-001 | `PERM-REPORT-OPERATIONAL` |
| A-51 | Attendance report | RPT-002 | `PERM-REPORT-OPERATIONAL` |
| A-52 | Incident report | RPT-005 | `PERM-REPORT-SAFETY` |
| A-53 | Data export | RPT-006 | `PERM-DATA-EXPORT` |
| A-54 | Audit trail | AUD-002 | `PERM-AUDIT-VIEW` |
| A-55 | Override register | AUD-003 | `PERM-AUDIT-VIEW` |
| A-56 | Child data access log | IAM-010 | `PERM-AUDIT-VIEW` |
| A-57 | Platform access log | AUD-004 | `PERM-AUDIT-VIEW` |

### Platform Operations

| ID | Screen | Permission |
|---|---|---|
| A-60 | Tenant list & onboarding | `PERM-PLATFORM-TENANT-ACCESS` |
| A-61 | Region profiles | `PERM-PLATFORM-REGION-MANAGE` |
| A-62 | Platform health | `PERM-PLATFORM-HEALTH-VIEW` |

---

## Coverage

Every feature in [`FEATURE_INVENTORY.md`](../01-product-discovery/FEATURE_INVENTORY.md) marked `R1` appears on at least one screen. Features marked `R2`/`L` have screens listed so navigation and information architecture accommodate them without restructuring later.

A CI check asserts every `R1` feature ID appears here.

## Adding a Screen

1. Assign the next ID for its client.
2. List feature IDs and the gating permission — a screen without a permission is unreachable (BR-IAM-002).
3. Add it to the relevant client document: [`PARENT_APP.md`](PARENT_APP.md), [`DRIVER_ATTENDANT_APP.md`](DRIVER_ATTENDANT_APP.md), or [`ADMIN_WEB.md`](ADMIN_WEB.md).
4. Define empty, loading, and error states ([`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md)).
