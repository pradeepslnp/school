# Table Specifications

**Document tier:** 3 — Database

One document per module. **Standard columns, types, naming, and RLS are defined in [`CONVENTIONS.md`](../CONVENTIONS.md) and are not repeated here** — each specification shows only the columns specific to that table.

| Module | Document |
|---|---|
| MOD-01 Tenancy | [`MOD-01-tenancy.md`](MOD-01-tenancy.md) |
| MOD-02 Identity & Access | [`MOD-02-identity.md`](MOD-02-identity.md) |
| MOD-03 / 04 Students & Guardians | [`MOD-03-04-students-guardians.md`](MOD-03-04-students-guardians.md) |
| MOD-05 / 06 Fleet & Staff | [`MOD-05-06-fleet-staff.md`](MOD-05-06-fleet-staff.md) |
| MOD-07 Routes & Stops | [`MOD-07-routes.md`](MOD-07-routes.md) |
| MOD-08 Trip Execution | [`MOD-08-trips.md`](MOD-08-trips.md) |
| MOD-09 Boarding & Handover 🔒 | [`MOD-09-boarding.md`](MOD-09-boarding.md) |
| MOD-10 / 11 Tracking & Alerts | [`MOD-10-11-tracking-alerts.md`](MOD-10-11-tracking-alerts.md) |
| MOD-12 Notification | [`MOD-12-notification.md`](MOD-12-notification.md) |
| MOD-13 / 14 Incidents & Absence 🔒 | [`MOD-13-14-incidents-absence.md`](MOD-13-14-incidents-absence.md) |
| MOD-16 / 17 Audit & Configuration 🔒 | [`MOD-16-17-audit-config.md`](MOD-16-17-audit-config.md) |

🔒 contains append-only tables.

MOD-15 Reporting owns no tables.

## Reading a Specification

Each table lists: owning module, purpose, module-specific columns, constraints, indexes, and the business rules it enforces structurally.

**"Enforced structurally" means the database rejects the violation** — not that the application checks it. Where a rule appears in a table's rule list, there is a constraint, a unique index, or a grant behind it, and a test proving it.
