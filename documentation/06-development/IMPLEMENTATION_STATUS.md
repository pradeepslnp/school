# Implementation status

**What is actually built, as opposed to what is specified.**

Every other document in `documentation/` describes the platform as designed. None of them says
which parts exist in code today, which is how a reader can spend an afternoon in
[`TRIPS_BOARDING_API.md`](../04-api/TRIPS_BOARDING_API.md) before discovering that most of it has
no controller behind it. This file is the answer to "can I use this yet?" and nothing else.

It is maintained by hand and is only as current as its date. When a module lands, the change
that lands it updates this file — that is part of the
[Definition of Done](DEFINITION_OF_DONE.md), not a follow-up.

**Last verified:** 2026-09-23, by reading source rather than documentation.

---

## Legend

| Mark | Meaning |
|---|---|
| ✅ | Built and usable end to end |
| 🟡 | Partly built — the gap is named in the row |
| ⛔ | Specified, no implementation |

---

## Backend modules

| Module | Package | Status | Notes |
|---|---|---|---|
| MOD-01 Tenancy | `com.guardian.tenancy` | ✅ | Organizations, schools, suspension, platform elevation (ADR-0016) |
| MOD-02 Identity | `com.guardian.identity` | ✅ | Phone OTP, email+password, invitations, password reset (ADR-0012), sessions, scopes |
| MOD-03 Students | `com.guardian.student` | ✅ | Enrolment, bulk import, withdrawal, discard (ADR-0019) |
| MOD-04 Guardians | `com.guardian.guardian` | ✅ | Guardian links with rights, pickup persons, custody restrictions. Linking a guardian provisions their login in the same transaction |
| MOD-05 Fleet | `com.guardian.fleet` | ✅ | Vehicles, documents with expiry, GPS device registration. Device *registration* only — see MOD-10 |
| MOD-06 Transport Staff | `com.guardian.staff` | ✅ | Staff, credentials, verification, duty assignments, eligibility |
| MOD-07 Routes & Stops | `com.guardian.routes` | ✅ | Routes (create **and edit**), stops with timetable, student assignment, operating days (V22). `school_calendar_exceptions` exists but has **no endpoint and no screen** — holidays can only be set in SQL today. Route *deactivation* is still unbuilt (BR-ROUTE-007) |
| **MOD-08 Trip Execution** | `com.guardian.trip` | 🟡 | **Generation, start, end, cancel and manifest materialisation are built.** No `close` — closing requires reconciliation, which is MOD-09. No `trip_staff` table, so per-trip crew substitution (BR-STAFF-006) is unsupported; the standing roster is used instead |
| MOD-09 Boarding | `com.guardian.boarding` | 🟡 | Handover **code issuance** only (P-12). Boarding and alighting events, handover redemption, and trip-close reconciliation are **not built** — this is the largest remaining gap |
| MOD-10 Tracking | — | ⛔ | No module. No position ingestion, no live position, no ETA, no history. ADR-0004 is still `Proposed` |
| MOD-11 Geofencing & Alerts | — | ⛔ | No module |
| MOD-12 Notification | `com.guardian.notification` | 🟡 | **Read side only.** `GET /notifications/me` and mark-as-read work; nothing in the platform ever *writes* a notification row, and there is no push, SMS or email dispatch for them |
| MOD-13 Incident & Emergency | — | ⛔ | No module. SOS and incidents are unbuilt |
| MOD-14 Absence | `com.guardian.absence` | ✅ | Declare, list, cancel |
| MOD-15 Reporting | — | ⛔ | No module |
| MOD-16 Audit | in `guardian-common` + API | ✅ | Audit records written in-transaction; read API and admin screen (A-54/A-55) |
| MOD-17 Configuration | — | ⛔ | No module. Tenant configuration and region profiles are unbuilt |
| MOD-18 Parent Experience | `com.guardian.parent` | ✅ | Read-only composition (ADR-0010, ADR-0020). Correct, but **has no tests** |
| MOD-19 Search | `com.guardian.search` | ✅ | Global search (ADR-0017, ADR-0018) |

---

## Clients

### Parent app (`flutter/parent_app`)

| Screen | Status | Notes |
|---|---|---|
| P-01 Login | ✅ | Phone + OTP |
| P-02 Home | 🟡 | Children list is live; journey state is derived from trips and boarding events, so it will read `AT_REST` until MOD-09's write path lands |
| P-03 Child detail | 🟡 | Child, class, route, stop, bus and crew are live; journey legs come from boarding events |
| P-04 Live trip map | ⛔ | UI built, **data provider returns fixtures** — no tracking backend exists. Stop coordinates are also absent from the documented contract |
| P-05 Journey history | 🟡 | Endpoint is live; reads `boarding_events`, which nothing writes yet |
| P-06 Declare absence | ✅ | |
| P-07 Pickup persons | ✅ | |
| P-08 Notification centre | 🟡 | Endpoint is live; reads `notifications`, which nothing writes yet |
| P-09 Notification preferences | ⛔ | Not built |
| P-10 Profile & language | 🟡 | Language and theme switchers are in the Home app bar; no profile screen |
| P-11 Incident detail | ⛔ | Not built; no incidents module |
| P-12 Handover verification | 🟡 | The parent can **issue** a code; nothing can **redeem** it (MOD-09) |

Localisation: English and Kannada, 198 keys, in sync (ADR-0013). Kannada values for
safety-critical copy are drafted and **held pending native-speaker sign-off** — see
`flutter/parent_app/lib/l10n/TRANSLATION_STATUS.md`.

### Driver & attendant app (`flutter/driver_attender_app`)

⛔ **Login and sync scaffolding only.** Two features exist (`login`, `sync`) and the only API calls
are the three auth endpoints. There is no manifest screen, no boarding capture, no trip control.
This is the client half of the MOD-09 gap.

### Admin console (`admin`)

| Screen | Status |
|---|---|
| A-40 Organizations | ✅ |
| A-41 School settings | ✅ |
| A-10 Students (+ guardians, custody, transport, route assignment) | ✅ |
| A-20 Vehicles | ✅ |
| A-23 Staff | ✅ |
| A-30 Routes (+ stops, crew, operating days) | ✅ |
| A-43 Users · A-44 Roles (read-only reference) | ✅ |
| A-54 Audit trail · A-55 Override register | ✅ |
| A-62 Platform health | ✅ |
| School holiday calendar | ⛔ — the table exists (V22); no API, no screen, so a holiday can only be set in SQL |
| Trip day view, live map, configuration, notification templates, region profiles | ⛔ |

**The admin console is not what blocks the parent app.** Every piece of setup data the parent app
reads — organisation, school, student, guardian with a phone, route, stops with times, stop
assignment, vehicle, driver, duty assignment — has a working screen and a working endpoint. What
was missing was the write path that records what happens on a journey.

---

## Tests

| Area | Test files |
|---|---|
| Backend | 47 + MOD-08's own |
| `guardian-parent` | **0** — the module serving every parent screen |
| `flutter/parent_app` | **0** |
| `admin` | **0** |
| `flutter/driver_attender_app` | **0** |

This is the largest standing deviation from [`DEFINITION_OF_DONE.md`](DEFINITION_OF_DONE.md) and
from `CLAUDE.md` §20.

---

## Known conflicts between documents and code

Recorded here rather than resolved by quietly editing the lower-tier document (`CLAUDE.md` §17).

1. **BR-TRIP-002 names a `STARTED` status that the schema does not have.** `ck_trips_status` (V5)
   permits `SCHEDULED`, `IN_PROGRESS`, `COMPLETED`, `CLOSED`, `CANCELLED`. Nothing in the design
   distinguishes "started" from "in progress" — no event between them, no screen that renders them
   differently. `TripStatus` follows the schema. **The rule text is what should change.**
2. **`MODULE_MAP.md` says MOD-07's package is `com.guardian.route`; the code uses
   `com.guardian.routes`.** Cosmetic, but it means a reader searching for the package finds
   nothing. MOD-08 uses `com.guardian.trip`, matching the map.
3. **ADR-0004 (real-time tracking pipeline) is still `Proposed`** while
   `REALTIME_TRACKING_DESIGN.md` refers to its decisions as settled. It should be accepted or
   superseded before MOD-10 is built.
4. **`05-ui/PARENT_APP.md` documents 6 of the 12 parent screens.** P-03 and P-05 are built in code
   with no UI specification at all; P-01, P-09, P-10 and P-11 have neither.

---

## What blocks what

```
MOD-09 boarding write path  ──┬──►  P-02 / P-03 journey state
                              ├──►  P-05 journey history
  (+ driver app capture)      └──►  trip close, reconciliation, no-show detection
                                          │
MOD-12 dispatch  ◄────────────────────────┘   ──►  P-08 notification centre, BR-TRIP-007

MOD-10 tracking  ─────────────────────────────►  P-04 live map, ETA, geofence alerts (MOD-11)
```

MOD-08 is built, so the top of that chain now has trips to anchor to. The next piece of work that
changes what a parent sees is **MOD-09's write path plus the driver app's capture screens** — and
it needs no new infrastructure, unlike MOD-10.
