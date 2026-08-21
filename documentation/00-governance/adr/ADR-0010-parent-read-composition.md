# ADR-0010: Parent-facing read composition

**Status:** Accepted
**Date:** 2026-08-10
**Affects:** [`MODULE_MAP.md`](../../01-product-discovery/MODULE_MAP.md), [`STUDENTS_GUARDIANS_API.md`](../../04-api/STUDENTS_GUARDIANS_API.md), [`PARENT_APP.md`](../../05-ui/PARENT_APP.md), `com.guardian.parent`

## Context

`GET /guardians/me/students` is the parent app's primary read. P-02 must answer *"is my child fine?"* with **zero taps** ([`PARENT_APP.md`](../../05-ui/PARENT_APP.md)), which means one response carrying, per child: identity and class (MOD-03), the guardian's right to see them (MOD-04), their stop (MOD-07), the trip they are on and its vehicle (MOD-05, MOD-08), whether they boarded (MOD-09), and whether they were declared absent (MOD-14).

[`STUDENTS_GUARDIANS_API.md`](../../04-api/STUDENTS_GUARDIANS_API.md) documents this endpoint under **MOD-04 Guardian**, and marks it *"proposed — not yet implemented server-side… it needs review before the backend commits to it."* This ADR is that review, because building it as documented is not possible.

**The endpoint as specified cannot live in MOD-04.** [`MODULE_MAP.md`](../../01-product-discovery/MODULE_MAP.md) places MOD-04 near the bottom of the dependency graph: MOD-03, MOD-05, MOD-06 and MOD-07 all depend *downward onto* it, and MOD-08 sits above all of those. For MOD-04 to read trip and boarding state it would have to depend upward on MOD-08 and MOD-09 — a cycle, which `LayerDependencyTest.modules_are_free_of_cycles` fails the build for, correctly.

Three constraints therefore hold simultaneously:

1. The response must be composed server-side. Per-child fan-out to `/trips/{id}/position` and `/trips/{id}/eta` is an N+1 over mobile data at the exact moment the answer matters most — the API document rejects it explicitly.
2. The composing code cannot sit in MOD-04, or in any module below MOD-08.
3. Cross-module *table* access is forbidden by cross-module rule 1: *"A module owns its tables. No module reads another module's tables directly."*

## Decision

**Introduce MOD-18 `com.guardian.parent`, a read-only composition module that owns no tables**, and move the parent app's composed reads into it.

```
                 ┌────────────────────────┐
                 │  MOD-18  Parent (read) │   owns no tables, no writes
                 └───────────┬────────────┘
   ┌──────────┬──────────┬───┴───┬──────────┬──────────┐
   ▼          ▼          ▼       ▼          ▼          ▼
MOD-03     MOD-04     MOD-07  MOD-08     MOD-09     MOD-14
Student   Guardian    Routes   Trip      Boarding   Absence
```

- It sits **above** every module it reads, so the dependency direction stays downward and the cycle disappears.
- It is **read-only**. It has no use case that writes, and its database role grants are `SELECT` only. Every parent-app *write* — declaring an absence, nominating a pickup person, marking a notification read — stays in the module that owns the table.
- It holds **no schema of its own**. Nothing here is a source of truth; it is a projection over other modules' state.
- Composition is one SQL projection, not a per-child loop, so the dashboard is a single round trip and a single query plan.

MOD-15 Reporting is the existing precedent for this shape — [`MODULE_MAP.md`](../../01-product-discovery/MODULE_MAP.md) already describes it as *"Read-only across modules; owns no operational data."* MOD-18 is that same pattern applied to a parent-facing rather than staff-facing read. It is separate from MOD-15 because reporting is permission-gated exports for staff, whereas this is scoped to `OWN_CHILDREN` and is on the hot path of the product's primary screen; merging them would put a parent's 10-second glance behind the export module's concerns.

### The accepted exception

Cross-module rule 1 says a module does not read another module's tables. **MOD-18 does exactly that, and that is the cost this ADR accepts.** It is bounded deliberately:

- **Read-only, enforced at the database.** The module's queries run under `guardian_app`, which holds no write grant it needs; a write from this module would fail at the database, not merely in review.
- **One projection, one file.** The cross-module SQL lives in a single adapter, so the coupling is greppable rather than spread across a module.
- **RLS still applies.** The projection runs under the same tenant policy as everything else; this is a relaxation of *module* boundaries, never of *tenant* boundaries.
- **Scope is enforced in the query, not after it.** Every projection joins through `guardian_student_links` on the calling guardian, so a child the caller is not linked to cannot be returned at all (BR-IAM-005). There is no post-filter to forget.

The alternative that preserves rule 1 — MOD-08/09 publishing a denormalised `student_journey_states` projection table that MOD-04 reads — is the better end state at scale and is deliberately left open: MOD-18's port would then be re-implemented against that table with no change above it.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Endpoint in MOD-04, calling up into MOD-08/09 | A module dependency cycle. Fails `modules_are_free_of_cycles`, and the test is right — this is the ball of mud it exists to prevent. |
| Client composes from per-resource endpoints | Rejected by [`STUDENTS_GUARDIANS_API.md`](../../04-api/STUDENTS_GUARDIANS_API.md): N+1 over mobile data, on the screen that must answer in one glance. Also moves the `OWN_CHILDREN` scope decision onto the client. |
| Put it in MOD-15 Reporting | Architecturally identical, semantically wrong. Reporting is staff exports and audit-heavy; the parent dashboard would inherit concerns it does not have, and MOD-15's permissions are the wrong gate for `OWN_CHILDREN`. |
| Event-sourced `student_journey_states` projection maintained by MOD-08/09 | The right answer at scale and preserves rule 1 fully. Rejected **for now** under KISS: it adds a projection to keep consistent and backfill before there is load that needs it. MOD-18's port makes the switch invisible above it. |
| Materialised view over the same joins | Same coupling, plus a refresh cadence to tune. A stale dashboard is precisely the failure BR-TRACK-003 exists to prevent, so buying speed with staleness is the wrong trade here. |

## Consequences

**Positive**
- The documented endpoint becomes buildable without weakening the cycle rule.
- One query per dashboard load; freshness is whatever the database holds, with no cache to go stale.
- Parent-facing composition has one home, so the next composed screen has an obvious place to go.
- Writes stay with their owning modules, so ownership of safety-relevant state is unchanged.

**Negative / accepted cost**
- A second place knows the shape of other modules' tables. A column rename in MOD-08 can break MOD-18 — mitigated by the projection being one file, and by integration tests over the real schema.
- MOD-18 must be kept honest: the moment it grows a write, this ADR has been violated. The `SELECT`-only grant is the guard.
- Two modules now serve `/guardians/…` paths (MOD-04 writes, MOD-18 reads), which is a seam a reader has to learn.

## Reversal Cost

**Low.** MOD-18 owns no tables and no writes, so removing it deletes code and nothing else. Replacing the projection with a MOD-08-maintained `student_journey_states` table is a new adapter behind the existing `ParentReadModel` port.

## Verification

1. `modules_are_free_of_cycles` passes with MOD-18 present — the module depends downward only.
2. An integration test asserts a guardian requesting the dashboard receives only children they hold an active link to, and that a second tenant's guardian receives none of them (BR-IAM-005, BR-TEN-004).
3. A schema test asserts `com.guardian.parent` holds no `@Entity` and no migration creates a table owned by it.
4. A test asserts the dashboard is served by a single query, not a per-child loop.
5. Every timestamp in the response is UTC, and `meta.school` carries the school's zone (BR-CFG-006).
