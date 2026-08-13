# GIT WORKFLOW

**Document tier:** 6 — Development
**Status:** Active

---

## Repositories

Seven repositories, listed in [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md). Everything below applies identically to each — same branch names, same commit format, same review bar. The differences are only these:

**A change lands in as few repositories as it can.** Most work touches one. If a change needs three, that is a signal worth reading: either the boundaries are wrong, or the change is really three changes.

**Cross-repository changes merge back-to-front — dependency first.** `guardian-core` before the apps that consume it; `guardian-docs` before the backend code that a new business rule governs. Each PR cites the others by URL in its `Refs:` line, and the dependency PR states that dependents are waiting so nobody merges it and walks away.

**The tree is only green when the repositories agree.** `guardian-backend`'s architecture tests parse `guardian-docs`, so a merged rule with no test turns the backend red — in a different repository, on someone else's branch. That is the cost of the split, paid deliberately: the alternative is documentation that drifts silently.

---

## Branches

| Branch | Purpose |
|---|---|
| `main` | Always deployable. Protected. |
| `feature/<id>-<slug>` | Feature work — `feature/BRD-014-left-behind-alert` |
| `fix/<id>-<slug>` | Defect fix |
| `chore/<slug>` | Tooling, dependencies, docs |
| `hotfix/<slug>` | Production fix, branched from `main` |

**Branch names carry the feature ID** from [`FEATURE_INVENTORY.md`](../01-product-discovery/FEATURE_INVENTORY.md). Work without an ID is untracked work.

Trunk-based: branches are short-lived, ideally under two days. Long branches diverge, and merge pain leads to skipped review.

---

## Commits

Conventional Commits:

```
<type>(<scope>): <subject>

<body — why, not what>

Refs: BRD-014, BR-SAFE-001
```

Types: `feat` · `fix` · `docs` · `refactor` · `test` · `chore` · `perf` · `build`

```
feat(boarding): raise critical alert for unaccounted students at trip close

Reconciliation now blocks CLOSED while any item is unresolved, and
dispatches NTF-SAFE-01 to driver, attendant, manager, and guardians.
Bypasses preferences and quiet hours per BR-NTF-006.

Refs: BRD-014, BR-SAFE-001, BR-TRIP-009
```

**The body explains why.** The diff already shows what.

**`Refs:` cites feature and business rule IDs** — this is what lets someone find the intent behind a change three years later.

---

## Pull Requests

Every change goes through a PR. No direct pushes to `main`.

### Template

```markdown
## Requirement Summary
## Documents Referenced
## Business Rules Applied
## Impact Analysis
Business · Database · API · UI · Security · Testing
## Test Cases
## Documentation Updated
## Future Considerations
```

This mirrors the response format in [`INSTRUCTIONS.md`](../INSTRUCTIONS.md). A PR that cannot fill these sections has not established what it is doing or why.

### Requirements to merge

- [ ] CI green — build, all tests, architecture tests, Spotless, security scan
- [ ] At least one approving review; **two for safety-critical (🔴) changes**
- [ ] Business rule IDs cited in code and tests
- [ ] Documentation updated — `guardian-docs` PR open and linked, merged first
- [ ] No new `TODO` without a linked issue
- [ ] [`DEFINITION_OF_DONE.md`](DEFINITION_OF_DONE.md) satisfied

### Size

Under 400 changed lines where possible. Beyond that, review quality drops sharply and approval becomes a formality — which is how defects reach `main` in a safety system.

Split refactoring from behaviour change into separate PRs. A behaviour change hidden inside a large rename is effectively unreviewed.

---

## Review

Reviewers check, in order:

1. **Correctness against the business rules cited** — do the rules say what the code assumes?
2. **Safety implications** — could this weaken a 🔴 control?
3. **Tenant isolation** — new tables have RLS; new queries are scoped
4. **Authorisation** — endpoints declare a permission; object-level scope is checked
5. **Audit** — safety-relevant changes write audit records in the same transaction
6. **Architecture** — layering, module boundaries, no logic in UI
7. **Tests** — business rule IDs referenced; error and edge cases covered
8. **Documentation** — updated alongside the code

Reviews are on the code, not the author. Blocking comments state what must change and why; suggestions are marked as such.

### Safety-critical changes 🔴

Any change touching a 🔴 rule requires:

- **Two approvals**, one from someone who did not pair on it
- An explicit statement of what safety property is preserved
- Tests referencing the rule IDs
- An ADR if the control itself is being changed ([`BUSINESS_RULES.md`](../01-product-discovery/BUSINESS_RULES.md) change control)

---

## Merging

**Squash merge** to `main`. The squash message follows the commit format and carries the `Refs:` line.

One PR, one logical change, one commit on `main` — so `main`'s history is a readable list of changes, and reverting is a single operation.

Branches are deleted after merge.

---

## Documentation Changes

**Documentation is the source of truth** ([`INSTRUCTIONS.md`](../INSTRUCTIONS.md)). Code that disagrees with a document is a defect in one of the two.

| Change | Also update |
|---|---|
| New feature | `FEATURE_INVENTORY.md`, API doc, UI doc, test cases |
| New business rule | `BUSINESS_RULES.md` + a test citing its ID |
| New table | `guardian-docs/03-database/tables/`, migration **with RLS** |
| New endpoint | API doc, `PERMISSION_MATRIX.md` if a new permission |
| New error | `ERROR_CATALOG.md` + localisation keys |
| New notification | `NOTIFICATION_CATALOG.md` + templates |
| Architectural decision | An ADR — never prose buried in another document |

All of these live in `guardian-docs`, so documentation can no longer land in the same PR as the code. It still lands in the same **change**: open the `guardian-docs` PR first, link it from the code PR, and merge docs first. Neither merges alone.

The one-PR rule existed because a follow-up PR for documentation is a documentation update that will not happen. Splitting the repositories does not retire that risk, it relocates it — which is why "docs PR open and linked" is a merge requirement above, not a convention.

---

## Hotfixes

1. Branch from `main`.
2. Minimal fix, plus a **regression test** — a hotfix without one invites the same incident.
3. Two approvals regardless of size.
4. Merge, deploy, verify.
5. Follow up with the root-cause fix if the hotfix was a mitigation.

Speed does not waive the regression test or the second approval. Those are what stop a hasty fix causing a second incident.

---

## What Is Never Committed

Secrets, credentials, tokens, keys · real child or guardian data, including in fixtures · `.env` files · build output · IDE configuration · large binaries.

Secret scanning runs in CI and on pre-commit hooks. **A committed secret is treated as compromised and rotated**, not deleted from history and forgotten.
