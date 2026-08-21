# PRODUCT PRINCIPLES

**Document tier:** 0 — Governance
**Status:** Active

Principles exist to settle arguments. Each one below states what it means, what it costs, and how to apply it when it conflicts with another principle.

---

## 1. Child Safety First

**Means:** When a design choice affects a child's physical safety, that consideration outranks cost, convenience, elegance, and performance.

**In practice:**
- A safety event is recorded even when the network is down; it syncs later.
- Ambiguity resolves conservatively — an unverified handover is blocked, not permitted with a warning.
- Safety-critical flows have no "skip" that is not audited and attributed.

**Cost accepted:** More friction for staff. Slower flows. More storage.

**Conflict resolution:** Wins against every other principle in this document.

---

## 2. Parent Peace of Mind

**Means:** A parent should learn their child's status without having to ask, and should not be alarmed by information that does not warrant alarm.

**In practice:**
- Notifications are prompt, specific, and calm: *"Aarav boarded Bus 12 at Green Park at 7:42 AM."*
- Absence of news is itself communicated — a delayed bus generates a message before a parent starts worrying.
- Alerts are graded. A two-minute delay is not the same event as a route deviation.

**Cost accepted:** Notification infrastructure complexity; per-guardian preference management.

**Conflict resolution:** Yields to Child Safety First. A safety alert is sent even if it alarms.

---

## 3. School Operational Efficiency

**Means:** Staff workflows minimise manual effort, repeated data entry, and cognitive load.

**In practice:**
- Data is entered once. Student records flow into routes, trips, and attendance without re-keying.
- Bulk operations are first-class: importing students, reassigning a route, closing a term.
- The driver interface is designed for a person near a moving vehicle: large targets, few decisions.

**Cost accepted:** More engineering effort on import, bulk, and defaulting behaviour.

**Conflict resolution:** Yields to Child Safety First. A verification step that protects a child is not removed because it is slow.

---

## 4. Trust Through Transparency

**Means:** The platform's record of what happened is complete, attributable, and available to those entitled to see it.

**In practice:**
- Every safety event carries actor, timestamp, device, and location.
- Overrides are permitted where operationally necessary, but always recorded with a reason.
- Parents can see their own child's journey history; they cannot see other children.

---

## 5. Configuration over Hardcoding

**Means:** Behaviour that varies by tenant, region, school, or policy is configuration — never a code branch.

**In practice:**
- Alert thresholds (overspeed, deviation radius, delay tolerance) are tenant configuration.
- Notification channels, templates, and languages are configurable.
- Regional concerns — phone formats, SMS regulation, required vehicle documents — are data, not code.

**Test:** If a new customer in a new country would require a code change to onboard, the design has failed this principle.

---

## 6. Inclusive by Default

**Means:** The platform serves parents across a wide range of literacy, language, device quality, and connectivity.

**In practice:**
- Critical information survives translation and is available over SMS, not only in-app.
- The parent app is usable on low-end devices and intermittent networks.
- Accessibility is a requirement, not an enhancement — see [`documentation/05-ui/ACCESSIBILITY.md`](05-ui/ACCESSIBILITY.md).

---

## 7. Data Minimisation

**Means:** The platform collects the least child data necessary to deliver safety outcomes, and keeps it no longer than needed.

**In practice:**
- Location history for children is derived from vehicle position, not per-child tracking devices.
- Retention periods are configured per tenant and enforced automatically.
- Exports and reports are permission-gated and audited.

**Conflict resolution:** Yields to Child Safety First and to legal retention obligations.

---

## Applying Principles to a Decision

When two principles conflict, resolve in this order:

```
Child Safety First
   ↓
Data Minimisation / legal obligation
   ↓
Parent Peace of Mind
   ↓
Trust Through Transparency
   ↓
School Operational Efficiency
   ↓
Inclusive by Default
   ↓
Configuration over Hardcoding
```

Record the resolution in the relevant business rule or ADR so the same argument is not had twice.
