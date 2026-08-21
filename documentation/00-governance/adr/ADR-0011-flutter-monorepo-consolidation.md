# ADR-0011: Consolidate the Flutter/Dart clients into a single Melos-managed monorepo

**Status:** Proposed
**Date:** 2026-08-21
**Affects:** `flutter/parent_app/`, `flutter/driver_attender_app/`, `flutter/teacher_app/`, `admin/`, `flutter/shared_packages/guardian_theme/`, [`PROJECT_STRUCTURE.md`](../../06-development/PROJECT_STRUCTURE.md), `.github/workflows/ci.yml`, `.vscode/launch.json`, `.vscode/tasks.json`, root `CLAUDE.md` §1, §15

## Context

Four of this workspace's seven git repositories are Flutter/Dart, and three of them consume the fourth: `flutter/parent_app`, `flutter/driver_attender_app`, and `admin` all take a `pubspec.yaml` local `path:` dependency on `flutter/shared_packages/guardian_theme`. `flutter/teacher_app` will join this group once it's built.

This coupling currently exists as independent git repositories linked only by relative filesystem paths, with no package manager or monorepo tool enforcing the relationship. The 2026-08 folder restructure (moving these four repos into the nested `flutter/` layout) demonstrated the cost of that directly: the same dependency needed a different relative path in each of the three consumers (`../shared_packages/guardian_theme` from the two apps under `flutter/`, `../flutter/shared_packages/guardian_theme` from `admin`, one level further away), every app's own README carried a now-stale tree diagram and dependency description that had to be corrected by hand, and one README had been describing a `guardian-core` package that was never actually built — drift nobody had caught. None of this was a one-off mistake; it's the structural failure mode of coupling repos by relative path instead of by a tool designed for it.

Beyond the restructure, the day-to-day cost of the current arrangement is: a change to `guardian_theme`'s public API can silently break up to three consumers with no single CI signal catching all three at once; there is no enforced version compatibility between the package and its consumers; and a fresh clone of the workspace has to get four separate repos checked out at exactly the right relative depths before `flutter pub get` succeeds in any of them.

## Decision

**Consolidate `flutter/parent_app`, `flutter/driver_attender_app`, `flutter/teacher_app`, `admin`, and `flutter/shared_packages/guardian_theme` into one git repository, managed with Melos and Dart/Flutter pub workspaces.**

The backend (`backend/`) is explicitly out of scope for this decision and remains its own repository — different language, different build tool (Gradle vs. pub/Flutter), different release cadence, and combining it would require heavier polyglot tooling (Bazel, Nx) that is disproportionate to this team's current size. This ADR only consolidates the stack that is already one language and already shares code.

Within the new repo, package boundaries stay exactly as they are today (each app keeps its own `pubspec.yaml`, its own five-part feature structure per `CLAUDE.md` §10, and `guardian_theme` stays a separate package with no reverse dependency on any app) — only the git-repository boundary changes, from four repos to one.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| **Status quo** — keep four independent repos coupled by relative `path:` dependencies | Already shown to be fragile in practice (this restructure); no atomic cross-repo changes; no CI signal when a shared-package change breaks a consumer; onboarding requires cloning four repos at the correct relative depths. |
| **Fold the backend in too** — one repository for the entire platform | Different language and build tool (Java/Gradle vs. Dart/Flutter) would need heavy polyglot build tooling (Bazel, Nx) to avoid every CI run rebuilding everything; backend and Flutter clients don't need a shared release cadence. The cost is disproportionate to the benefit at this team's size. |
| **Publish `guardian_theme` to a private pub registry** instead of a path dependency or monorepo | Adds registry hosting and a publish step for a package with exactly three internal consumers; slows the iteration loop (publish, bump, `pub get` versus instant workspace resolution). Worth reconsidering only if the package needs consumers outside this workspace. |
| **Git submodules** to formalize the existing path coupling without merging repos | Submodules are a well-known source of day-to-day friction (detached HEAD confusion, forgetting to update the pinned commit) and do not fix the underlying relative-path fragility inside the submodule itself — this trades one confusing mechanism for another rather than removing it. |

## Consequences

**Positive**

- A change to `guardian_theme` and its effect on all three (soon four) consumers lands and is tested atomically, in one commit and one CI run, instead of being coordinated across four repos by hand.
- Melos's affected-package detection means CI only rebuilds and re-tests what actually changed, rather than everything or nothing.
- A single `git clone` produces a working workspace — no more coordinating four repos at specific relative depths before `flutter pub get` succeeds anywhere.
- Removes the entire class of bug this ADR was written in response to: a relative path that's correct for one consumer and wrong for another.

**Negative / accepted cost**

- Real, one-time migration effort: a decision on preserving vs. squashing four separate git histories, retiring (or archiving) three GitHub repositories, and a third rewrite this month of `.github/workflows/ci.yml`, `.vscode/launch.json`, and `.vscode/tasks.json`.
- Melos becomes a new tool in the toolchain that the team has to learn, alongside plain `flutter`/`dart` commands.
- If any of these clients ever needs a genuinely independent release cadence or a separate owning team, it has to be deliberately split back out (see Reversal Cost) rather than already being separate.

**Neutral**

- `backend/`, `infrastructure/`, and `documentation/` are unaffected.
- Current apps already share a release rhythm in practice — `.vscode/launch.json` already runs all three DEV or all three PROD together — so this decision does not remove independence that was actually being used.

## Reversal Cost

**Moderate.** The mitigation that keeps the exit open: `guardian_theme` must stay a clean, one-directional dependency (apps depend on it; it depends on nothing app-specific), so splitting a client back out later means extracting one directory with a stable public API, not untangling entangled code.

**Reconsider when:** `flutter/teacher_app` or a future client needs a release cadence genuinely independent of the others, or is owned exclusively by a different team — at that point, extracting it back to its own repository is the trigger this ADR should be revisited against, not a reason to avoid consolidating now.

## Verification

1. `melos bootstrap` succeeds from a clean clone of the new repository with no manual path setup.
2. CI runs `melos run analyze` / `melos run test` with affected-package scoping and passes on the current codebase post-migration.
3. A deliberate breaking change to `guardian_theme`'s public API, introduced as a test of this ADR, causes a CI failure in every consuming app in the same run — proving the atomic-change benefit is real, not aspirational.
