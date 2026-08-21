# PROJECT CHARTER

**Document tier:** 0 — Governance
**Priority:** 2 (subordinate only to [`INSTRUCTIONS.md`](INSTRUCTIONS.md))
**Status:** Active

---

## 1. Mission

Guardian Platform ensures that **every child's journey between home and school is observed, verified, and accounted for** — and that the adults responsible for that child know its status without having to ask.

## 2. Problem Statement

School transport is the least-instrumented part of a school day. A child leaves the sight of one responsible adult and arrives in the sight of another, and in between:

- Parents have no visibility and call the school office for reassurance, consuming staff time.
- Schools reconcile boarding manually on paper, so errors surface hours later — if at all.
- A child boarding the wrong bus, alighting at the wrong stop, or being handed to an unauthorised adult is detected late, when detection matters most early.
- A child left asleep on a parked vehicle is a rare event with catastrophic consequences and no systemic control.

The platform closes that observation gap.

## 3. Product Scope

### In Scope

| Area | Description |
|---|---|
| Fleet & devices | Vehicles, GPS devices, documents, assignment to routes |
| Driver & attendant | Records, credentials, verification status, duty assignment |
| Routes & stops | Route definition, stops, schedules, student-to-stop assignment |
| Trip execution | Trip lifecycle from scheduled to closed, with live position |
| Boarding & attendance | Board and alight events, per-student journey record |
| Guardian handover | Verified release of a child to an authorised adult |
| Live tracking | Real-time vehicle location and stop ETA for authorised viewers |
| Geofencing & alerts | Stop arrival, school arrival, route deviation, overspeed, unscheduled stop |
| Notifications | Multi-channel, templated, per-tenant configurable |
| Incidents & SOS | Panic alerts, incident reports, escalation chains |
| Absence | Parent declares child not travelling for a given trip |
| Reporting | Operational, compliance, and safety reporting |
| Audit | Immutable record of safety-relevant actions |
| Administration | Multi-tenant onboarding, roles, permissions, configuration |

### Explicitly Out of Scope (Non-Goals)

Stating these protects the platform from scope drift. Each may be revisited by charter amendment, never by assumption.

- **Not an academic ERP.** No gradebooks, timetables, curriculum, or examinations.
- **Not a fees or accounting system.** Transport fee *billing* is out of scope; transport fee *eligibility flags* may be consumed from an external system.
- **Not a fleet-maintenance ERP.** Vehicle documents and fitness expiry are tracked for compliance; workshop, parts, and fuel management are not.
- **Not a general messaging product.** Notifications are event-driven and templated; free-form parent–teacher chat is out of scope.
- **Not an HR system.** Driver records exist for safety and compliance, not payroll or leave management.
- **Not a consumer product.** Every user belongs to a tenant. There is no public self-signup.

## 4. Stakeholders

| Stakeholder | Primary interest |
|---|---|
| Parent / Guardian | Knowing their child is safe, without effort |
| Student | Being transported safely; minimal interaction burden |
| Driver | Clear route guidance, low-distraction interface |
| Attendant / Bus Matron | Accurate boarding records, ability to raise alarms |
| Transport Manager | Fleet utilisation, route efficiency, incident response |
| School Admin | Compliance, parent satisfaction, reduced call volume |
| Principal / Management | Institutional risk reduction, reporting |
| Platform Operator (Super Admin) | Tenant onboarding, platform health |
| Regulator / Auditor | Evidence of compliance and duty of care |

Detail: [`documentation/01-product-discovery/STAKEHOLDERS.md`](01-product-discovery/STAKEHOLDERS.md)

## 5. Success Measures

| Measure | Target |
|---|---|
| Boarding events recorded electronically | > 99% of journeys |
| Parent notification latency (board/alight) | < 10 seconds p95 |
| Live position freshness | < 30 seconds p95 |
| Unaccounted-child incidents | Zero, with detection under 5 minutes of trip close |
| Reduction in transport-related calls to school office | > 60% within two terms |
| Cross-tenant data leakage incidents | Zero, structurally prevented |

## 6. Architectural Commitments

These are charter-level and may not be reversed by a lower-tier document:

1. **Multi-tenancy is structural.** Tenant isolation is enforced at the database layer, not only in application code.
2. **Safety events are immutable.** Boarding, handover, and incident records are append-only and auditable.
3. **Configuration over hardcoding.** Tenant, regional, and policy variance lives in configuration.
4. **No client is trusted.** Authorisation is decided server-side, always within tenant scope.
5. **Degradation is designed.** Loss of connectivity on a vehicle must not lose safety data.

## 7. Constraints & Risks

| Risk | Mitigation |
|---|---|
| Connectivity gaps on routes | Offline-capable driver app with queued sync (see ADR-0008) |
| GPS device heterogeneity | Device adapters behind a common ingestion port |
| Child PII sensitivity | Data minimisation, encryption, retention policy, strict RBAC |
| Notification fatigue | Per-tenant and per-guardian notification preferences |
| Safety-critical false negatives | Trip-close reconciliation and left-behind detection |

## 8. Governing Documents

This charter is implemented through the tiers described in [`documentation/00-governance/DOCUMENT_HIERARCHY.md`](00-governance/DOCUMENT_HIERARCHY.md).

## 9. Amendment

Changes to Sections 3 (Scope) or 6 (Architectural Commitments) require an ADR recording the reason, alternatives considered, and affected documents.
