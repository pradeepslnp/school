# ADR-0020: Staff-facing student transport and journey reads

**Status:** Accepted
**Date:** 2026-09-19
**Amends:** [ADR-0010](ADR-0010-parent-read-composition.md)
**Affects:** [`MODULE_MAP.md`](../../01-product-discovery/MODULE_MAP.md) MOD-18; [`FEATURE_INVENTORY.md`](../../01-product-discovery/FEATURE_INVENTORY.md) STU-009; [`STUDENTS_GUARDIANS_API.md`](../../04-api/STUDENTS_GUARDIANS_API.md); [`ADMIN_WEB.md`](../../05-ui/ADMIN_WEB.md) A-11; `com.guardian.parent`

## Context

School staff open a student's record (A-11) and need to see where the child is and which bus they are on. The product is built around exactly this question ([`PROJECT_CHARTER.md`](../../PROJECT_CHARTER.md): *where is my child, and who is responsible for them right now?*). The admin console's planned screens all start from the bus or the trip instead: live map, active trips, trip manifest, trip replay. None of them starts from the child. An office answering a parent's call would have to go from the child to the route, to today's trip, and then find the child in that trip's manifest.

Answering from the child means composing across modules:

- **Now:** the child's route and stop (MOD-07), that route's bus (MOD-05), and today's duty crew (MOD-06).
- **Once trips, boarding and tracking exist:** today's trip (MOD-08), the child's boarding events (MOD-09), and the bus's position (MOD-10).

All of these sit above MOD-03 Student, which cannot depend upward on them. The parent app faced the same problem, and [ADR-0010](ADR-0010-parent-read-composition.md) answered it with MOD-18: a read-only composition module that owns no tables. MOD-18 also holds the only implementation of journey state (`JourneyState`: on board, arrived at school, handed over, no-show, unaccounted).

## Decision

**MOD-18 also serves school staff.** It becomes the read composition for a child's transport and journey, for two audiences:

| Audience | Endpoint | Scope decided in the query |
|---|---|---|
| Guardian | `/guardians/me/students…` (unchanged) | `guardian_student_links` on the caller (BR-IAM-005) |
| School staff | `/students/{id}/transport` (now), `/students/{id}/journey` (planned) | the caller's school scope (BR-IAM-006) |

- **Staff reads are gated by `PERM-STUDENT-VIEW`.** School scope is applied in the WHERE clause. Out-of-scope and not-found are the same `404 STUDENT_NOT_FOUND`.
- **Each staff read writes a data-access record** (BR-IAM-012), through the audit port and in the read's own transaction, as `GetStudentUseCase` does. This is the module's only write. It never writes to a table it reads.
- **One projection file per audience:** `JdbcParentReadModel` and `JdbcStudentTransportReadModel`. The future staff journey projection must reuse the parent projection's journey-state derivation. It must not write a second one, because journey state is a business rule and has exactly one implementation.
- **`GET /students/{id}/transport` returns the plan, not a location.** It gives the route and stop the child is assigned to per direction, the route's default bus, and the crew on duty today (in the school's timezone). The console labels it "assigned". Only boarding records on a running trip say where a child is, and a trip may run with a substitute bus or crew.
- **Crew is shown by name only.** Staff phones stay on the Drivers screen behind `PERM-STAFF-VIEW`.

The module keeps its name, `guardian-parent` / `com.guardian.parent`. Renaming it touches every file in the module for no behavioural gain. The name is now narrower than the module's role, and that is recorded here rather than fixed.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| A new staff-facing read module | Would need its own copy of journey-state derivation, and that derivation is a business rule. Two implementations drift, and a drifted "on board" is a safety defect. |
| The console composes it from `/route-assignments`, `/routes`, `/vehicles`, `/duty-assignments` | Picking which duty applies to a direction on a date is business logic in the UI (ENGINEERING_PRINCIPLES.md). It also needs four permissions a Principal only partly holds, and makes four round trips. |
| Extend `GET /students/{id}/route-assignments` in MOD-07 | MOD-07 cannot read MOD-05 vehicles or MOD-06 duty assignments without a new module dependency, and it could never reach trips and boarding for the journey half. |
| Put it in MOD-15 Reporting | MOD-15 is not built, and ADR-0010 already rejected reporting as the home for a live per-child read. |

## Consequences

**Positive**
- The student record answers "which bus?" today and gains "where is the child now?" as soon as trips and boarding land, from the same module and the same state rules the parent app uses.
- Staff scope is enforced in SQL, so there is no post-filter to forget.

**Negative / accepted cost**
- MOD-18 now reads MOD-05 and MOD-06 tables as well. This is the same bounded exception ADR-0010 accepts, and it is contained in one adapter file.
- The module's name no longer describes all of its audience.

## Reversal Cost

**Low.** The staff read is one port, one adapter and one controller. Moving it to another module changes no contract.

**Reconsider if:**
- MOD-08/09 publish the denormalised `student_journey_states` projection ADR-0010 anticipates, in which case both audiences' reads move onto it
- a third audience needs child-journey reads, at which point the module should be renamed

## Verification

- `EndpointPermissionTest` holds `GET /students/{id}/transport` to `PERM-STUDENT-VIEW`.
- Manual: a School Admin of school A asking for a student of school B in the same organization gets `404`, and no data-access record is written.
- Manual: a student with pickup and drop on a route with a default bus and a duty crew shows both legs with bus and crew; a route with no bus shows the gap.
