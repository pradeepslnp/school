# PERSONAS

**Document tier:** 1 — Product Discovery
**Status:** Active

Personas exist to make design arguments concrete. Where [`STAKEHOLDERS.md`](STAKEHOLDERS.md) lists roles and access, this document describes the conditions under which each person actually uses the product.

---

## Meera — Working Parent

**Context.** Two children, different schools, different routes. Commutes herself. Checks her phone between meetings.

**Conditions of use:** 10–20 second glances, one-handed, often on mobile data, sometimes on a crowded train.

**What she needs:** the answer to "is my child fine?" in the first screen, without navigation. A notification she can read from the lock screen without opening the app.

**What breaks her trust:** learning something went wrong from her child rather than from the app. Notifications so frequent she mutes them — after which the one that matters is also muted.

**Design consequences**
- Home screen answers the question without a tap; live map is a second-level detail, not the entry point.
- Notification copy is complete in the first line: *"Aarav boarded Bus 12 at Green Park, 7:42 AM."*
- Per-event notification preferences (NTF-007) exist so she can keep the important ones and drop the rest — and safety-critical events ignore that choice (BR-NTF-006).

---

## Ramesh — Driver

**Context.** Drives two routes each morning and afternoon. Twenty years' experience, moderate literacy in the platform's default language, uses a phone mounted on the dashboard.

**Conditions of use:** vehicle moving or briefly stopped, sunlight on the screen, engine noise, children boarding. **He should be interacting with the app as little as possible.**

**What he needs:** next stop, students expected there, and a way to raise an alarm without looking.

**What breaks his experience:** anything requiring typing. A screen that demands attention while the vehicle moves. Being blamed for something the record does not show.

**Design consequences**
- Large targets, high contrast, minimal text (see [`DRIVER_ATTENDANT_APP.md`](../05-ui/DRIVER_ATTENDANT_APP.md)).
- SOS reachable in one action from any screen (INC-001).
- Boarding operations belong to the attendant where one is assigned (BR-STAFF-005).
- Tracking is trip-scoped (BR-TRACK-001) — the platform is a safety tool, not surveillance of his day.

---

## Sunita — Attendant

**Context.** Responsible for 40 children on a vehicle. Boards a dozen at a stop in under two minutes while managing children who do not queue.

**Conditions of use:** standing in a moving-then-stopping vehicle, one hand on a rail, phone in the other. **Coverage drops on part of her route every single day.**

**What she needs:** to mark many children quickly, to know immediately who is missing, and to be certain about who may collect a child.

**What breaks her work:** an app that refuses to record because the network is down. A verification step that takes longer than the child takes to leave.

**Design consequences**
- **ADR-0008 (offline-first) exists primarily for Sunita.** Records are written locally and acknowledged instantly.
- Pending-sync count is always visible — silent queuing would hide failure from the person who most needs to know.
- Scan-first boarding with a manual fallback (BRD-001, BRD-002).
- Overrides exist because real situations demand them, and are always attributed and audited (BR-AUD-004).

---

## Anil — Transport Manager

**Context.** 30 vehicles, 45 routes, 2,000 students across two campuses. His day is exceptions.

**Conditions of use:** desktop with several tabs open; phone during a live incident.

**What he needs:** a single view of what is going wrong right now, ranked by severity. Fast reassignment when a vehicle or driver becomes unavailable. Evidence when a parent complains.

**What breaks his work:** an alert stream so noisy that real problems are buried. Data entry that duplicates what the school office already entered.

**Design consequences**
- Alert deduplication (BR-ALERT-005) and severity ranking are requirements, not polish.
- Bulk operations throughout (STU-002, RTE-004).
- Compliance blocking is enforced by the system (BR-FLEET-002, BR-STAFF-001) rather than left to his memory.
- Every override and exception is attributable, so complaints are answerable with a record.

---

## Fatima — School Admin

**Context.** Onboards several hundred students each term, mostly from spreadsheets of varying quality. Fields parent phone calls.

**What she needs:** import that reports errors clearly and lets her fix and retry, rather than failing wholesale.

**Design consequences**
- Bulk import with per-row validation and a downloadable error report (STU-002).
- Guardian rights are explicit at import (BR-GRD-001), because implied rights are how the wrong adult ends up authorised.
- Reduced call volume is a charter success measure — the parent app must answer the questions that generate those calls.

---

## Deepak — Platform Operator

**Context.** Runs the platform across all tenants. Onboards new organizations; occasionally investigates a support issue that requires looking at tenant data.

**What he needs:** the ability to help without unbounded access, and a record proving what he did.

**Design consequences**
- Cross-tenant access is a distinct, explicitly permissioned, always-audited path (BR-TEN-004, AUD-004). This is the single deliberate exception to tenant isolation and therefore the most instrumented one.
- Onboarding a tenant in a new region is configuration, not a deployment (ADR-0007).

---

## Non-Persona: The Student

Students are the subject of most data in this platform and, in most deployments, are not users of it.

**This is a design constraint, not an omission.** No safety control may depend on a child operating software correctly. Where students carry a credential (STU-007), it is a passive card or code that an attendant scans — the verification burden sits with the adult, always.
