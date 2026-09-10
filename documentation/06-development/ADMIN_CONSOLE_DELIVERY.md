# Admin Console — Delivery Sequence

**Tier:** 6 — Development · **Status:** Active

Ordered plan to finish the admin console (`admin/`) and the backend it needs. One row = one
Standard/Architectural increment: ADR if the row says so, then migration + module + endpoints +
admin screen + doc updates, verified per [`DEFINITION_OF_DONE.md`](DEFINITION_OF_DONE.md). Update
the Status column as each lands. Screen IDs are from [`05-ui/ADMIN_WEB.md`](../05-ui/ADMIN_WEB.md);
module IDs from [`01-product-discovery/MODULE_MAP.md`](../01-product-discovery/MODULE_MAP.md).

Legend: ✅ done · 🔨 in progress · ⬜ not started

---

## Already delivered

Auth/recovery · A-40 Organizations · A-41 School settings · A-10 Students · **A-12 Bulk import** ·
A-13 Guardian links & pickup persons · **A-14 Custody restrictions** · A-20 Vehicles + documents ·
A-23 Staff/drivers · A-30 Routes + stops · A-32 Student→route assignment · A-43 Users ·
A-44 Roles (read-only) · A-54/A-55 Audit trail + override register · A-62 Platform health.

**MOD-02 Identity — backend completed** (see [`backend/guardian-identity/README.md`](../../backend/guardian-identity/README.md)):
self-service + admin session management (IAM-004), role & scope reassignment over the nine fixed
templates (IAM-005/IAM-007, `PUT /users/{id}/role`), staff deactivation revoking sessions and
duties (IAM-008). **Admin UI still to wire:** A-43 gains "change role / move scope" and "revoke
sessions" actions; a "my sessions" surface; A-44 stays a reference screen (tenant-defined roles,
IAM-006, remain deferred pending an ADR).

---

## Phase A — self-contained gaps (no new operational module)

| # | Increment | Needs | ADR? | Status |
|---|---|---|---|---|
| A1 | **A-14 Custody Restrictions** — `custody_restrictions` record/list/lift use cases (BR-GRD-008/BR-HAND-006/BR-AUD-004), `CustodyRestrictionController`, error-toned panel on the student record with required reason, gated to `PERM-CUSTODY-RESTRICTION-MANAGE` | table + API already specced (V4, STUDENTS_GUARDIANS_API.md) | no | ✅ |
| A2 | **A-56/A-57 access logs** — read/query endpoints over `data_access_records` (BR-IAM-012) and cross-tenant ops (BR-TEN-004), + two read-only screens | data already written by `GetStudentUseCase`; needs query endpoints | no | ⬜ |
| A3 | **MOD-17 Configuration** — typed registry (CFG-001), scoped resolution (CFG-002), safety floors/ceilings (CFG-004), change audit (CFG-005); seed the keys other modules already assume | new module `guardian-config` | **yes** — new module, confirm the fourth cross-repo dep rule (§9) is untouched | ⬜ |
| A4 | **A-45/A-47 Configuration & Alert Rules screen** — bounds shown inline, old/new confirmation, audited | A3 | no | ⬜ |
| A5 | **A-31 Route Editor (map)** — drag stops, geofence radius on a map, inline validation; replaces the form editor | Google Maps in `admin`; maybe a stop-reorder endpoint | no | ⬜ |

## Phase B — the operations spine

| # | Increment | Needs | ADR? | Status |
|---|---|---|---|---|
| B1 | **MOD-08 Trips** — schedule generation from the operating calendar (TRP-001), manifest materialisation (TRP-003, subtracts absences), lifecycle (TRP-004), cancel (TRP-005), trip-close reconciliation gate (TRP-008, BR-SAFE-001) | new module `guardian-trip`; consumes MOD-07 routes, MOD-14 absence | **yes** — ADR-0004 area, trip is the anchor for every safety event | ⬜ |
| B2 | **MOD-09 Boarding (full)** — boarding/alighting events (BRD-001/003), off-manifest + wrong-stop overrides (BRD-006/007), handover recording + override + no-receiver (BRD-008/010/012), compensating corrections | expand `guardian-boarding` beyond code issuance; needs B1 | maybe | ⬜ |
| B3 | **A-01 Operations Dashboard v1** — trip counts, on-bus/delivered counts; alerts panel present but empty until Phase C | B1 + B2 | no | ⬜ |

## Phase C — tracking & alerts

| # | Increment | Needs | ADR? | Status |
|---|---|---|---|---|
| C1 | **MOD-10 Tracking** — device ingestion port (ADR-0004), position storage + retention, live position / ETA / history endpoints (TRK-002/005/006) | new module `guardian-tracking`; needs B1 | **yes** — ingestion pipeline design | ⬜ |
| C2 | **A-02 Fleet Live Map** — clustered vehicles, status colour+icon+label, side panel | C1 | no | ⬜ |
| C3 | **MOD-11 Geofencing & Alerts** — stop-arrival/approach, route deviation, overspeed (+ duration), no-show, wrong-vehicle; alert dedup + lifecycle (BR-ALERT-005/006) | new module `guardian-alerts`; needs C1 + B1 | **yes** | ⬜ |
| C4 | **A-04 Alert Inbox** + wire A-01's alerts panel + A-06 Safety Exceptions | C3 + B2 | no | ⬜ |

## Phase D — incident & emergency

| # | Increment | Needs | ADR? | Status |
|---|---|---|---|---|
| D1 | **MOD-13 Incident & SOS** — raise SOS (INC-001), escalation chain until acknowledged (INC-002, BR-SAFE-006 🔴), acknowledge/resolve, incident report + severity audience (INC-004) | new module `guardian-incident`; needs MOD-12 notification (exists) + B1 | **yes** | ⬜ |
| D2 | **A-05 SOS / Incident console** — live escalation trail | D1 | no | ⬜ |

---

## Cross-cutting, do before Phase B

- **Fix the red backend build** — `./gradlew build` fails at `spotlessCheck` on files from commit `1f6a288` (pre-existing, unrelated). One `./gradlew spotlessApply` commit. Blocks trusting CI on every increment after.
- **Notification catalogue coverage** — each new module's events must be added to `01-product-discovery/NOTIFICATION_CATALOG.md` as they land, not after.
- **Tenant-isolation test per new module** (§20) — RLS + a cross-tenant test is part of each module row above, not a separate task.
