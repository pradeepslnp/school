# STAKEHOLDERS

**Document tier:** 1 — Product Discovery
**Status:** Active

Who the platform serves, what each party needs, and what each party can do harm with if access is wrong.

---

## Primary Stakeholders

### Parent / Guardian

**Needs:** to know their child is safe without having to ask.

| Wants | Fears |
|---|---|
| Know the bus is coming, and when | Not being told something went wrong |
| Know their child boarded and alighted | Being told too much, too often, until they stop reading |
| Reach someone when something is wrong | Their child's location being visible to strangers |

**Sees:** own children only. Never another family's child, never a full passenger list.
**Acts:** declares absence, nominates authorised pickup persons, sets notification preferences, receives handover verification.
**Risk if over-permissioned:** exposure of other families' children — the platform's most serious data risk.

---

### Student

**Needs:** to be transported safely with minimal burden.

Students are the subject of nearly all data in the platform and, in most deployments, are not users of it. Older students may hold a card or QR credential for boarding.

**Design consequence:** the student never has to operate software correctly for the safety controls to work. Verification is performed by the attendant, not by the child.

---

### Driver

**Needs:** to know the route and to not be distracted.

| Wants | Fears |
|---|---|
| Clear next-stop guidance | Being blamed for something the record does not show |
| A way to signal trouble instantly | An interface that demands attention while driving |
| Low interaction while moving | Being tracked as surveillance rather than safety |

**Sees:** the current trip's manifest and route only. No historical data on other trips, no student contact detail beyond what a handover requires.
**Acts:** starts and ends trips, raises SOS, reports incidents.
**Design consequence:** the driver interface is glanceable and one-handed. Boarding operations belong to the attendant where one is assigned.

---

### Attendant (Bus Matron)

**Needs:** to account for every child on the vehicle.

The attendant is **the primary operator of the safety controls**. Boarding, alighting, and handover verification are their work.

| Wants | Fears |
|---|---|
| Fast marking of many children at once | Losing a record because the network dropped |
| Certainty about who may collect a child | Releasing a child to the wrong adult |
| A way to flag a problem without stopping the trip | Being unable to record a real event because the system says no |

**Design consequence:** ADR-0008 (offline-first) exists mainly for this person. Overrides must exist for genuine situations, but must always be attributed and audited.

---

### Transport Manager

**Needs:** to run the fleet and respond when something goes wrong.

**Sees:** all vehicles, routes, trips, and students within their school(s).
**Acts:** defines routes and stops, assigns students and staff, manages vehicles and documents, responds to incidents and SOS, authorises overrides.
**Risk if over-permissioned:** broad access to child data; access is scoped to their school and audited.

---

### School Admin

**Needs:** compliance, parent satisfaction, and fewer phone calls.

**Sees:** their school. Manages students, guardians, staff accounts, and school configuration.
**Acts:** onboards students and guardians, configures notification policy and school timings, runs reports.

---

### Principal / School Management

**Needs:** assurance that institutional duty of care is discharged and evidenced.

**Sees:** dashboards and reports, not day-to-day operational detail.
**Design consequence:** reporting must answer "can we prove what happened" as well as "how are we performing".

---

### Platform Operator (Super Admin)

**Needs:** to onboard tenants and keep the platform healthy.

**Sees:** across organizations — the only role that does.
**Design consequence:** every cross-tenant action is explicitly permissioned and audited without exception (ADR-0001). This role is the one deliberate hole in tenant isolation, so it is the one most tightly instrumented.

---

## Secondary Stakeholders

### Regulator / Auditor

Not a system user, but a consumer of its output. Needs evidence: who was responsible, what happened, when, and whether policy was followed.

**Design consequence:** audit records are append-only and retained per policy (see [`AUDIT_AND_LOGGING.md`](../02-system-design/AUDIT_AND_LOGGING.md)). Overrides carry reasons because a reason-less override is not evidence of anything.

### Emergency Services

Consumers of information during an incident. Need vehicle location, passenger count, and a contact — quickly, from someone who has it.

### Transport Vendor

Where fleets are outsourced, the vendor employs drivers and owns vehicles. Their staff need operational access without school-wide student data access.

**Design consequence:** vendor-scoped roles are a real requirement, not a variant of transport manager.

---

## Access Summary

| Stakeholder | Scope | Reads child data |
|---|---|---|
| Guardian | Own children | Own children only |
| Student | Self | Minimal |
| Driver | Current trip | Manifest during trip |
| Attendant | Current trip | Manifest + handover detail during trip |
| Transport Manager | School | Yes, operational |
| School Admin | School | Yes, administrative |
| Principal | School | Aggregated |
| Vendor Staff | Assigned routes | Manifest only |
| Super Admin | Platform | Yes — fully audited |

Authoritative mapping: [`PERMISSION_MATRIX.md`](PERMISSION_MATRIX.md).

---

## Conflicts Between Stakeholders

Real tensions, resolved by [`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md):

| Tension | Resolution |
|---|---|
| Parents want live tracking always; drivers experience it as surveillance | Tracking is trip-scoped. Vehicles are not tracked outside trip windows. |
| Attendants want fast boarding; safety wants verification | Verification is fast by design (scan), not optional. Overrides exist and are audited. |
| Schools want fewer notifications; parents want more | Per-guardian preferences, with safety-critical events exempt (`BR-NTF-006`). |
| Managers want full history; data minimisation wants less | Retention is configured per tenant within legal bounds; access is audited. |
