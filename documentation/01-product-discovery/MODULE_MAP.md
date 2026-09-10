# MODULE MAP

**Document tier:** 1 — Product Discovery
**Status:** Active

The platform's functional decomposition. Module boundaries are also **code boundaries** — each maps to a backend module ([`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §2) and owns its tables.

---

## Module Index

| ID | Module | Package | Owns |
|---|---|---|---|
| MOD-01 | Tenancy | `com.guardian.tenancy` | Organizations, schools, branches |
| MOD-02 | Identity & Access | `com.guardian.identity` | Users, roles, permissions, sessions |
| MOD-03 | Student Registry | `com.guardian.student` | Students, classes, enrolment |
| MOD-04 | Guardian Management | `com.guardian.guardian` | Guardians, relationships, authorised pickup persons |
| MOD-05 | Fleet | `com.guardian.fleet` | Vehicles, devices, vehicle documents |
| MOD-06 | Transport Staff | `com.guardian.staff` | Drivers, attendants, credentials, duty assignment |
| MOD-07 | Routes & Stops | `com.guardian.route` | Routes, stops, schedules, student assignments |
| MOD-08 | Trip Execution | `com.guardian.trip` | Trip lifecycle, manifests, trip staff |
| MOD-09 | Boarding & Attendance | `com.guardian.boarding` | Boarding events, handovers, reconciliation |
| MOD-10 | Tracking | `com.guardian.tracking` | Position ingestion, live position, history, ETA |
| MOD-11 | Geofencing & Alerts | `com.guardian.alert` | Geofences, alert rules, alert instances |
| MOD-12 | Notification | `com.guardian.notification` | Events, templates, preferences, dispatch |
| MOD-13 | Incident & Emergency | `com.guardian.incident` | SOS, incidents, escalation |
| MOD-14 | Absence | `com.guardian.absence` | Absence declarations |
| MOD-15 | Reporting | `com.guardian.reporting` | Reports, exports, dashboards |
| MOD-16 | Audit | `com.guardian.audit` | Audit records, access logs |
| MOD-17 | Configuration | `com.guardian.config` | Tenant configuration, region profiles, reference data |
| MOD-18 | Parent Experience | `com.guardian.parent` | **Owns nothing.** Read-only composition of the parent app's screens (ADR-0010) |

---

## Dependency Direction

Modules depend downward only. A cycle is an architecture defect and fails the build.

```
                       ┌──────────────┐
                       │ MOD-15  Reporting │
                       └────────┬─────────┘
     ┌──────────────┬───────────┼───────────┬──────────────┐
     ▼              ▼           ▼           ▼              ▼
┌─────────┐  ┌───────────┐ ┌─────────┐ ┌─────────┐  ┌───────────┐
│ MOD-13  │  │  MOD-11   │ │ MOD-09  │ │ MOD-14  │  │  MOD-12   │
│Incident │  │  Alerts   │ │Boarding │ │ Absence │  │Notification│
└────┬────┘  └─────┬─────┘ └────┬────┘ └────┬────┘  └─────┬─────┘
     └─────────────┴────────────┼───────────┘             │
                                ▼                          │
                        ┌───────────────┐                  │
                        │ MOD-08  Trip  │◄─────────────────┘
                        └───────┬───────┘
          ┌─────────────┬───────┼───────┬─────────────┐
          ▼             ▼       ▼       ▼             ▼
    ┌─────────┐  ┌──────────┐ ┌──────┐ ┌────────┐ ┌─────────┐
    │ MOD-07  │  │  MOD-05  │ │MOD-06│ │ MOD-03 │ │ MOD-10  │
    │ Routes  │  │  Fleet   │ │Staff │ │Student │ │Tracking │
    └────┬────┘  └────┬─────┘ └──┬───┘ └───┬────┘ └────┬────┘
         └────────────┴──────────┴─────────┤           │
                                            ▼           │
                                     ┌────────────┐     │
                                     │  MOD-04    │     │
                                     │  Guardian  │     │
                                     └─────┬──────┘     │
                                           │            │
         ┌─────────────────────────────────┴────────────┘
         ▼
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │MOD-02 Identity│  │MOD-17 Config │   │ MOD-16 Audit │
   └───────┬───────┘  └──────┬───────┘   └──────┬───────┘
           └─────────────────┴──────────────────┘
                             ▼
                     ┌───────────────┐
                     │MOD-01 Tenancy │
                     └───────────────┘
```

**Foundation modules** (MOD-01, 02, 16, 17) may be depended upon by anything and depend on nothing above them.
**MOD-16 Audit** is written to by every module through a port; it depends on none of them.
**MOD-12 Notification** consumes domain events; it does not call other modules synchronously.

---

## Module Detail

### MOD-01 Tenancy
Organizations, schools, branches; onboarding and lifecycle. Establishes tenant context for every request. **This is the reference implementation module** — new modules copy its structure.

### MOD-02 Identity & Access
Users, credentials, sessions, roles, permissions, scope resolution. Implements ADR-0006. Guardian and staff identity converge here; a person may be both a guardian and a staff member.

### MOD-03 Student Registry
Student records, class/grade, enrolment status, transport eligibility. Enrolment is one-at-a-time or bulk from an uploaded spreadsheet (STU-002), both through one enrolment path. Source of truth for who exists; does not own transport assignment (MOD-07).

### MOD-04 Guardian Management
Guardian records, guardian–student relationships with rights, and authorised pickup persons with validity windows. Owns the answer to *"may this adult collect this child?"* — consumed by MOD-09.

### MOD-05 Fleet
Vehicles, GPS devices, and vehicle documents with expiry. Document *types* come from MOD-17 (ADR-0007). Raises compliance alerts through MOD-11.

### MOD-06 Transport Staff
Drivers and attendants, their credentials and expiry, and duty assignment. Enforces that unqualified or unverified staff cannot be assigned (`BR-STAFF-003`).

### MOD-07 Routes & Stops
Route definition, ordered stops with geofence radius and scheduled times, and student-to-stop assignment per direction. Produces the expected manifest a trip consumes.

### MOD-08 Trip Execution
The operational centre. Owns the trip lifecycle, materialises the manifest at trip start, and holds trip-level state. Every safety event is anchored to a trip.

### MOD-09 Boarding & Attendance
Boarding and alighting events, handover verification, and trip-close reconciliation. **The most safety-critical module.** Records are append-only; corrections are compensating records.

### MOD-10 Tracking
Position ingestion via device adapters, live position cache, durable history, ETA calculation. Implements ADR-0004.

### MOD-11 Geofencing & Alerts
Evaluates position and trip state against rules: stop arrival, school arrival, route deviation, overspeed, unscheduled stop, idle vehicle. Thresholds are tenant configuration.

### MOD-12 Notification
Turns domain events into delivered messages. Recipient resolution, preferences, templates, channels, dispatch records. Implements ADR-0005.

### MOD-13 Incident & Emergency
SOS from driver, attendant, or device; incident reports; severity, escalation chains, acknowledgement. Highest notification priority.

### MOD-14 Absence
Guardian declares a child not travelling for a trip or date range. Removes the child from the expected manifest so reconciliation does not raise a false alarm.

### MOD-15 Reporting
Operational, compliance, and safety reporting; exports. Read-only across modules; owns no operational data. All exports permission-gated and audited.

### MOD-18 Parent Experience
Composes the parent app's read surfaces — the dashboard (P-02) and child detail (P-03) — into one response each, so a parent's 10-second glance is a single round trip rather than a per-child fan-out.

**Read-only, and owns no tables.** It sits above every module it reads, which is what lets `GET /guardians/me/students` carry live journey state without MOD-04 depending upward on MOD-08 — the cycle that made the documented endpoint unbuildable. Every parent-app *write* stays in the owning module: absences in MOD-14, pickup persons in MOD-04, notification reads in MOD-12.

Its cross-module table access is a deliberate, bounded exception to cross-module rule 1, argued and constrained in [`ADR-0010`](../00-governance/adr/ADR-0010-parent-read-composition.md).

### MOD-16 Audit
Append-only audit records written in-transaction by every module via a port. Also records data-access events for child PII.

### MOD-17 Configuration
Typed tenant configuration, region profiles, reference data, localisation resources. Implements ADR-0007. Safety-critical floors are enforced here.

---

## Cross-Module Rules

1. **A module owns its tables.** No module reads another module's tables directly — access goes through the owning module's application layer.
2. **No cycles.** Enforced by an ArchUnit test.
3. **Communication:** synchronous calls downward through application services; upward and lateral communication is by domain events.
4. **Shared kernel:** only `guardian-common` (tenant context, error types, audit port, common value objects). It contains no business rules.
5. **A new module requires** a row in this table, a package, an entry in [`FEATURE_INVENTORY.md`](FEATURE_INVENTORY.md), and its own tables documented in [`documentation/03-database/tables/`](../03-database/tables/).
