# PERMISSION MATRIX

**Document tier:** 1 — Product Discovery
**Status:** Active

The authoritative list of permissions and their assignment to roles. **Every API endpoint declares a permission ID from this document** — an endpoint referencing an unlisted permission fails the build ([`DOCUMENT_HIERARCHY.md`](../00-governance/DOCUMENT_HIERARCHY.md) invariant 3).

Format: `PERM-<AREA>-<ACTION>`.

---

## Scope Levels

Permission alone is insufficient — every check resolves permission **and** scope (BR-IAM-006).

| Scope | Meaning |
|---|---|
| `PLATFORM` | Across organizations. Platform operators only; always audited (BR-TEN-004). |
| `ORG` | Within the user's organization, all schools. |
| `SCHOOL` | Within assigned school(s). |
| `ROUTE` | Within assigned routes. |
| `TRIP` | Within the currently active trip only. |
| `OWN_CHILDREN` | Students the user is an active guardian of (BR-IAM-005). |
| `SELF` | The user's own record. |

---

## Roles

| Role | Default scope | Notes |
|---|---|---|
| `SUPER_ADMIN` | `PLATFORM` | Platform operator. Every cross-org action audited. |
| `ORG_ADMIN` | `ORG` | Group-level administration. |
| `SCHOOL_ADMIN` | `SCHOOL` | Day-to-day school administration. |
| `PRINCIPAL` | `SCHOOL` | Read and reporting; minimal write. |
| `TRANSPORT_MANAGER` | `SCHOOL` | Fleet, routes, trips, incidents. |
| `VENDOR_STAFF` | `ROUTE` | Outsourced operator; manifest access only. |
| `DRIVER` | `TRIP` | Current trip only. |
| `ATTENDANT` | `TRIP` | Current trip; owns boarding operations. |
| `GUARDIAN` | `OWN_CHILDREN` | Parent or guardian. |

Roles are templates. Tenants may define custom roles from the same permission set; they cannot invent permissions.

---

## Matrix

`✔` granted · `✔*` granted within a narrower scope · blank = denied

### Tenancy & Configuration

| Permission | SUPER | ORG | SCH | PRIN | TM | VEND | DRV | ATT | GRD |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `PERM-ORG-CREATE` | ✔ | | | | | | | | |
| `PERM-ORG-VIEW` | ✔ | ✔ | | | | | | | |
| `PERM-ORG-EDIT` | ✔ | ✔ | | | | | | | |
| `PERM-ORG-SUSPEND` | ✔ | | | | | | | | |
| `PERM-SCHOOL-CREATE` | ✔ | ✔ | | | | | | | |
| `PERM-SCHOOL-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | | | | |
| `PERM-SCHOOL-EDIT` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-CONFIG-VIEW` | ✔ | ✔ | ✔ | ✔ | | | | | |
| `PERM-CONFIG-EDIT` | ✔ | ✔ | ✔* | | | | | | |
| `PERM-CONFIG-SAFETY-EDIT` | ✔ | ✔ | | | | | | | |

`PERM-CONFIG-SAFETY-EDIT` governs safety-relevant thresholds and remains bounded by platform floors (BR-CFG-003).

### Identity & Access

| Permission | SUPER | ORG | SCH | PRIN | TM | VEND | DRV | ATT | GRD |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `PERM-USER-CREATE` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-USER-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔* | | | | |
| `PERM-USER-EDIT` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-USER-DEACTIVATE` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-ROLE-MANAGE` | ✔ | ✔ | | | | | | | |
| `PERM-SESSION-REVOKE` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-PROFILE-SELF-EDIT` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |

### Students & Guardians

| Permission | SUPER | ORG | SCH | PRIN | TM | VEND | DRV | ATT | GRD |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `PERM-STUDENT-CREATE` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-STUDENT-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔* | ✔* | ✔* | ✔* |
| `PERM-STUDENT-EDIT` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-STUDENT-IMPORT` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-GUARDIAN-MANAGE` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-GUARDIAN-LINK` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-PICKUP-PERSON-MANAGE` | | | ✔ | | | | | | ✔* |
| `PERM-CUSTODY-RESTRICTION-MANAGE` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-HANDOVER-CODE-REQUEST` | | | | | | | | | ✔* |

`PERM-STUDENT-VIEW` scope narrows sharply: `VEND`/`DRV`/`ATT` see only the current trip manifest; `GRD` only their own children (BR-IAM-005). Non-guardian access is logged (BR-IAM-012).

`PERM-PICKUP-PERSON-MANAGE` for a guardian requires the "authorise handover" right on the relationship (BR-GRD-006).

`PERM-HANDOVER-CODE-REQUEST` (P-12) lets a guardian generate the short-lived verification code shown to the bus attendant at drop. Like `PERM-PICKUP-PERSON-MANAGE`, it requires `can_authorise_handover` on the specific relationship (BR-GRD-006) — the endpoint permission is necessary and not sufficient. Issuing a code is not itself a handover: verifying and redeeming it at the vehicle is the attendant-side flow BR-HAND-001 through BR-HAND-007 govern, which ships with the driver/attendant app.

### Fleet & Staff

| Permission | SUPER | ORG | SCH | PRIN | TM | VEND | DRV | ATT | GRD |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `PERM-VEHICLE-MANAGE` | ✔ | ✔ | ✔ | | ✔ | | | | |
| `PERM-VEHICLE-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔* | | | |
| `PERM-VEHICLE-DOCUMENT-MANAGE` | ✔ | ✔ | ✔ | | ✔ | | | | |
| `PERM-DEVICE-MANAGE` | ✔ | ✔ | | | ✔ | | | | |
| `PERM-STAFF-MANAGE` | ✔ | ✔ | ✔ | | ✔ | | | | |
| `PERM-STAFF-VERIFY` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-DUTY-ASSIGN` | ✔ | ✔ | | | ✔ | | | | |

### Routes & Trips

| Permission | SUPER | ORG | SCH | PRIN | TM | VEND | DRV | ATT | GRD |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `PERM-ROUTE-MANAGE` | ✔ | ✔ | ✔ | | ✔ | | | | |
| `PERM-ROUTE-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔* | ✔* | ✔* | |
| `PERM-ROUTE-ASSIGN-STUDENT` | ✔ | ✔ | ✔ | | ✔ | | | | |
| `PERM-TRIP-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔* | ✔* | ✔* | ✔* |
| `PERM-TRIP-START` | | | | | ✔ | | ✔ | ✔ | |
| `PERM-TRIP-END` | | | | | ✔ | | ✔ | ✔ | |
| `PERM-TRIP-CANCEL` | ✔ | ✔ | ✔ | | ✔ | | | | |
| `PERM-TRIP-CLOSE` | | | ✔ | | ✔ | | | | |
| `PERM-MANIFEST-AMEND` | | | ✔ | | ✔ | | | ✔ | |

`PERM-TRIP-VIEW` for a guardian is limited to trips carrying one of their children (BR-TRACK-002).

### Boarding & Handover

| Permission | SUPER | ORG | SCH | PRIN | TM | VEND | DRV | ATT | GRD |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `PERM-BOARDING-RECORD` | | | | | ✔ | | ✔ | ✔ | |
| `PERM-BOARDING-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | | ✔* | ✔* | ✔* |
| `PERM-BOARDING-CORRECT` | | | ✔ | | ✔ | | | ✔ | |
| `PERM-BOARDING-OVERRIDE` | | | ✔ | | ✔ | | | ✔ | |
| `PERM-HANDOVER-RECORD` | | | | | ✔ | | ✔ | ✔ | |
| `PERM-HANDOVER-OVERRIDE` | | | ✔ | | ✔ | | | ✔ | |
| `PERM-RECONCILIATION-RESOLVE` | | | ✔ | | ✔ | | | ✔ | |

Every permission in this block is override-capable and therefore **always audited with a reason** (BR-AUD-004). `PERM-HANDOVER-OVERRIDE` additionally notifies all guardians and the transport manager (BR-HAND-003).

### Tracking, Alerts, Incidents

| Permission | SUPER | ORG | SCH | PRIN | TM | VEND | DRV | ATT | GRD |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `PERM-TRACKING-LIVE-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔* | | | ✔* |
| `PERM-TRACKING-HISTORY-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | | | | |
| `PERM-ALERT-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔* | | | |
| `PERM-ALERT-RESOLVE` | ✔ | ✔ | ✔ | | ✔ | | | | |
| `PERM-SOS-RAISE` | | | | | ✔ | | ✔ | ✔ | |
| `PERM-SOS-ACKNOWLEDGE` | ✔ | ✔ | ✔ | ✔ | ✔ | | | | |
| `PERM-INCIDENT-CREATE` | | | ✔ | | ✔ | ✔ | ✔ | ✔ | |
| `PERM-INCIDENT-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔* | | | ✔* |
| `PERM-INCIDENT-RESOLVE` | ✔ | ✔ | ✔ | | ✔ | | | | |

Guardian `PERM-INCIDENT-VIEW` is limited to incidents affecting their own child (BR-INC-004, BR-NTF-007).

### Absence, Notification, Reporting, Audit

| Permission | SUPER | ORG | SCH | PRIN | TM | VEND | DRV | ATT | GRD |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `PERM-ABSENCE-DECLARE` | | | ✔ | | ✔ | | | | ✔* |
| `PERM-ABSENCE-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | | ✔* | ✔* | ✔* |
| `PERM-NOTIFICATION-TEMPLATE-MANAGE` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-NOTIFICATION-SELF-VIEW` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| `PERM-NOTIFICATION-PREFERENCE-SELF` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| `PERM-NOTIFICATION-DELIVERY-VIEW` | ✔ | ✔ | ✔ | | ✔ | | | | |
| `PERM-REPORT-OPERATIONAL` | ✔ | ✔ | ✔ | ✔ | ✔ | | | | |
| `PERM-REPORT-SAFETY` | ✔ | ✔ | ✔ | ✔ | ✔ | | | | |
| `PERM-REPORT-COMPLIANCE` | ✔ | ✔ | ✔ | ✔ | ✔ | | | | |
| `PERM-DATA-EXPORT` | ✔ | ✔ | ✔ | | | | | | |
| `PERM-AUDIT-VIEW` | ✔ | ✔ | ✔ | ✔ | | | | | |
| `PERM-AUDIT-EXPORT` | ✔ | ✔ | | | | | | | |

`PERM-ABSENCE-DECLARE` for a guardian requires the "declare absence" right (BR-ABS-001).
`PERM-DATA-EXPORT` is always audited with actor, scope, and record count (BR-RPT-002).

`PERM-NOTIFICATION-SELF-VIEW` covers the notification centre (P-08) and marking an entry read. Held by everyone, and scoped to the caller's **own** notifications — it grants no visibility into anyone else's, so it is never a route to another family's child (BR-NTF-007 🔴). It exists as a row here rather than being left as "authenticated" because an endpoint with no declared permission fails the build (BR-IAM-002), and "everyone may read their own" is a scope statement worth writing down rather than an absence of one.

### Platform Operations

| Permission | SUPER | Others |
|---|:-:|:-:|
| `PERM-PLATFORM-TENANT-ACCESS` | ✔ | |
| `PERM-PLATFORM-HEALTH-VIEW` | ✔ | |
| `PERM-PLATFORM-REGION-MANAGE` | ✔ | |

`PERM-PLATFORM-TENANT-ACCESS` is the **only** path across the tenant boundary (BR-TEN-004). Every use writes an audit record naming the target organization and the justification (AUD-004).

---

## Enforcement

1. **Deny by default** (BR-IAM-002). An endpoint without a declared permission is unreachable.
2. **Server-side only** (BR-IAM-001). Client-supplied roles are ignored.
3. **Permission and scope are checked together.** Holding `PERM-STUDENT-VIEW` never implies seeing every student.
4. **Resolved per request** (BR-IAM-004), never read from the token.
5. **Verified in CI.** A test asserts every endpoint declares a permission that exists here, and a test per role asserts denied permissions actually return `403`.
