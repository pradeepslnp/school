# CI / CD

**Document tier:** 8 — Deployment
**Status:** Active

---

## Per-repository pipelines

Each repository runs its own workflow. Not every repository runs every stage — the table says which, and the stage descriptions below are written once and referenced from each.

| Repository | Stages it runs |
|---|---|
| `backend` | 1, 2, 3, 4, 5, 6, 8–11 |
| `guardian-core` | 1 (`dart analyze`, `dart test`), 3 |
| `flutter/parent_app`, `flutter/driver_attender_app` | 1, 3, 5, 7, 8–11 |
| `admin` | 1, 3, 7, and the load budget under stages 5–7 |
| `documentation` | 4 (link integrity only — the rest need code to check against) |
| `infrastructure` | 3 (compose lint, image scan) |

Two consequences of the split are worth stating plainly rather than discovering:

**Stage 4 belongs to `backend`, not `documentation`.** The traceability checks compare documentation against code, so they can only run where the code is. `documentation` can verify its own links resolve; it cannot verify that a rule it documents has a test. A merge to `documentation` therefore has to trigger `backend`'s pipeline — a repository-dispatch from the docs workflow — or a rule can be published and stay untested until something unrelated turns the backend red.

**The client repositories check out `guardian-core` beside themselves.** Their pub path dependency resolves on disk, so a build that clones only the app will fail at `pub get`. Same for `backend`, which needs `documentation` checked out or `GUARDIAN_DOCS_PATH` pointed at it.

---

## Pipeline

```
Push to branch
   ▼
1  Build + unit + architecture tests          ~2 min
   ▼
2  Integration + contract tests               ~5 min   (Testcontainers)
   ▼
3  Static analysis + security scan            ~2 min
   ▼
4  Documentation traceability checks          ~1 min
   ▼
── PR to main ──────────────────────────────────────
   ▼
5  E2E journeys                               ~10 min
   ▼
6  Safety-critical matrix (if 🔴 touched)     ~8 min
   ▼
7  Accessibility (if UI touched)              ~3 min
   ▼
── Merge ───────────────────────────────────────────
   ▼
8  Build artefacts once, tag by commit
   ▼
9  Deploy to staging (automatic)
   ▼
10 Staging verification
   ▼
11 Deploy to production (manual approval)
```

**Fast stages first.** A compile error should fail in two minutes, not after a ten-minute E2E suite.

---

## Stage 1 — Build, Unit, Architecture

```bash
./gradlew build            # compile + unit tests
./gradlew architectureTest # ArchUnit
```

Architecture tests run early because they are fast and catch the errors most expensive to fix later — a layering violation found after a feature is complete means rewriting it ([`ARCHITECTURE_ENFORCEMENT.md`](../06-development/ARCHITECTURE_ENFORCEMENT.md)).

## Stage 2 — Integration & Contract

Testcontainers PostgreSQL with the real schema, real migrations, real RLS.

Includes schema invariants that cannot be checked statically:

- Every `tenant_id` table has RLS **enabled and forced**
- Every policy declares `USING` **and** `WITH CHECK`
- `guardian_app` lacks `BYPASSRLS`
- Append-only tables reject `UPDATE` and `DELETE`
- Pooled-connection tenant context does not leak

Contract tests assert every denied cell in [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md) returns `403`, and that generated OpenAPI matches the documented contract.

## Stage 3 — Static Analysis & Security

Spotless, Error Prone, SpotBugs, `flutter analyze` (warnings are errors), dependency vulnerability scan, container image scan, and **secret scanning**.

A detected secret fails the build and the secret is **rotated**, not merely removed from the diff — once committed, it is compromised.

## Stage 4 — Documentation Traceability 🔴

The check that keeps documentation honest as the code grows:

| Check | Fails when |
|---|---|
| Business rule coverage | A rule in `BUSINESS_RULES.md` has no `@BusinessRule` test |
| 🔴 double coverage | A safety-critical rule has fewer than two test levels |
| Feature coverage | An `R1` feature has no API doc entry or test case |
| Permission validity | An endpoint declares a permission absent from the matrix |
| Error catalogue | A returned code is absent from `ERROR_CATALOG.md` |
| Notification templates | A catalog ID lacks a default-locale template per channel |
| Link integrity | A link within `documentation` points at a missing path |

Link integrity is scoped to links **inside** `documentation`. Links that reach into a sibling repository (`../../backend/…`) resolve only in a full local checkout, so CI cannot verify them without cloning everything — treat those as documentation for humans, and keep them few.

**Documentation is the source of truth** ([`INSTRUCTIONS.md`](../INSTRUCTIONS.md)). Without this stage that statement decays into an aspiration within a few sprints.

## Stages 5–7 — Journeys, Safety, Accessibility

E2E covers the eight journeys in [`USER_JOURNEYS.md`](../01-product-discovery/USER_JOURNEYS.md).

The safety-critical matrix runs whenever a 🔴 rule is touched, and nightly regardless. **A failure blocks release — no waiver, no fix-forward** ([`SAFETY_CRITICAL_TEST_MATRIX.md`](../07-testing/SAFETY_CRITICAL_TEST_MATRIX.md)).

Accessibility checks run on UI changes; the admin console additionally tracks its load budget, whose sustained breach reopens ADR-0003.

---

## Build Once, Promote

Artefacts are built once at stage 8, tagged with the commit SHA, and promoted unchanged through staging to production.

**Rebuilding per environment means testing something other than what ships.** Configuration differs by environment; the binary does not.

---

## Deployment

Rolling deployment with health checks. New instances must pass readiness before old ones are drained.

### Migration ordering

Migrations run **before** the new application version, and every migration is expand-contract ([`MIGRATION_STRATEGY.md`](../03-database/MIGRATION_STRATEGY.md)) — so the old version continues working against the new schema.

That property is what makes rollback possible: reverting is redeploying the previous artefact, with no schema change required.

### Migration safety in production

- A **verified recent backup** is confirmed before migrations run
- `lock_timeout` and `statement_timeout` set — a migration fails fast rather than blocking a school run
- Deployments avoid peak windows; the bimodal load profile makes the safe window obvious and generous
- Flyway's lock prevents concurrent migration across instances

### Rollback

| Situation | Action |
|---|---|
| Application defect | Redeploy previous artefact — schema still compatible |
| Migration defect | Corrective **forward** migration |
| Both | Restore from verified backup (last resort) |

No `undo` scripts exist. A rollback script written when a change is fresh and executed years later during an incident is untested code run under pressure ([`MIGRATION_STRATEGY.md`](../03-database/MIGRATION_STRATEGY.md)).

---

## Post-Deployment Verification

Automatic, before the deployment is marked successful:

1. Health and readiness across all three deployables
2. Smoke tests: login, read a trip, record a boarding event
3. Migration applied and schema version correct
4. **RLS assertions against the live database** — every `tenant_id` table forced
5. Error rate and latency within budget for 10 minutes
6. Notification dispatch succeeding

Failure triggers automatic rollback to the previous artefact.

Check 4 runs in production deliberately. RLS is the platform's primary security control, and a migration that created a table without a policy must be caught in minutes, not at the next audit.

---

## Release Cadence

Continuous to staging on every merge. Production releases are batched and scheduled outside peak windows.

**Hotfixes** follow the same pipeline with no stages skipped. Speed comes from a small diff, not from reduced verification — a hasty fix causing a second incident is the common failure mode ([`GIT_WORKFLOW.md`](../06-development/GIT_WORKFLOW.md)).

Mobile releases follow store review timelines. **The API maintains backward compatibility within `v1`** ([`API_STANDARDS.md`](../04-api/API_STANDARDS.md)) — a parent running an old app build must keep receiving safety notifications, and cannot be forced to update mid-term.

---

## Pipeline Hygiene

- Pipelines are code, reviewed like application code.
- **No manual step between test and artefact.**
- **Flaky tests are fixed or deleted, never retried.** A retried test is one nobody believes — unacceptable for the tests that matter most here.
- Build times tracked; a slow pipeline gets bypassed, and a bypassed pipeline protects nothing.
