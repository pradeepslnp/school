# ADR-0013: Interim client-bundled localisation for the Flutter apps (English/Kannada)

**Status:** Accepted
**Date:** 2026-09-07
**Affects:** `flutter/parent_app`, `flutter/driver_attender_app`, `admin` (Flutter Web). Does not affect the backend, `flutter/teacher_app` (unimplemented placeholder), or `flutter/shared_packages/guardian_theme`.

## Context

[`ADR-0007`](ADR-0007-regional-configuration.md) and `BR-CFG-005` already specify the platform's target localisation architecture: no user-facing string is ever bundled into a client. Every string — UI copy, API error messages, notification templates — is a `resource_key` resolved at runtime from a backend `localisation_resources` table via `GET /localisation/{locale}` (feature `CFG-006`, `documentation/04-api/REPORTING_AUDIT_CONFIG_API.md`). `CODING_STANDARDS_FLUTTER.md` documents the intended client call shape (`context.l10n.studentBoardedAt(...)`) and states it is "enforced by a lint and an architecture test."

As of this ADR, none of that exists yet: there is no `localisation_resources` migration, no backend module implementing `CFG-006`, and no client consuming it. `ADR-0007` itself is still `Status: Proposed`, even though half a dozen tier 5–10 documents already build on it as settled — that inconsistency is noted here but not resolved by this ADR; it is a separate governance cleanup.

The immediate need is a working English/Kannada experience in the three real Flutter apps (`parent_app`, `driver_attender_app`, `admin`) now, without first building a new backend module, a DB migration, and a client networking pattern that doesn't exist yet either — `CODING_STANDARDS_FLUTTER.md`'s reference to a shared `guardian_core` client is itself stale; `PROJECT_STRUCTURE.md` confirms `guardian_core` was never built and that a real shared package needs its own name and its own ADR (§9 of `CLAUDE.md` — a fourth cross-repo dependency needs an ADR). Building the full `CFG-006` backend, deciding that shared-package question, and localising three client apps in one pass was assessed as too large and too coupled a unit of work to do responsibly at once; this ADR deliberately narrows scope to the client side.

## Decision

For this pass, the three Flutter apps localise using Flutter's standard bundled mechanism — `flutter_localizations` + `intl`, ARB source files, `flutter gen-l10n` codegen — **not** the backend-driven `CFG-006` design. Concretely, per app:

1. `l10n.yaml` + `lib/l10n/app_en.arb` (source of truth, complete) + `lib/l10n/app_kn.arb` (Kannada; see translation status below).
2. `generate: true` under `flutter:` in `pubspec.yaml`; `flutter_localizations` (SDK) and `intl` added as dependencies.
3. A `context.l10n` extension on `BuildContext` (matching the call shape `CODING_STANDARDS_FLUTTER.md` already documents) resolving to the generated `AppLocalizations`.
4. Every `Text('literal')` and other user-facing string literal (hints, labels, tooltips, dialog copy, semantic labels, validation and error copy shown to a user) in `lib/` is replaced with a resource-key call. This is a hard bar, not a best-effort pass — the same "no string literal in a widget" bar `BR-CFG-005` sets, just enforced by hand-review in this pass rather than a lint, since building the custom-lint tooling was judged out of scope for an interim solution.
5. A locale switcher persisted locally (`shared_preferences`, a new per-app dependency — the standard, Flutter-team-maintained package for exactly this: a small non-secret preference that must survive restart), wired the same way each app already threads a `ValueNotifier`-backed cross-cutting app-shell preference (`parent_app`'s `ThemeController`/`ThemeScope` is the direct precedent copied here as `LocaleController`/`LocaleScope`). Default: follow system locale if it's `en` or `kn`, else `en`.
6. `MaterialApp`/`MaterialApp.router`'s `localizationsDelegates` and `supportedLocales` wired to the generated `AppLocalizations`, `locale` wired to the controller.

**Kannada content:** the source-of-truth English strings are complete and real. Kannada values are populated as **English-fallback placeholders** in `app_kn.arb` — a deliberate, tracked incompleteness, not a silent one. Each app's `lib/l10n/` carries a `TRANSLATION_STATUS.md` listing every resource key, its English value, and its status (`pending-kn-translation` for all of them at this pass), so the gap is visible and actionable rather than indistinguishable from a real translation. Safety-critical copy (wrong-bus/wrong-vehicle, handover override, no-show, unauthorised pickup — the `NTF-BOARD-*`/`NTF-HAND-*` family in `NOTIFICATION_CATALOG.md`, where these apps surface equivalent in-app copy) is called out explicitly in that file as requiring native-speaker sign-off before a Kannada value ships, not just any translation.

## Alternatives Considered

| Alternative | Why rejected (for this pass) |
|---|---|
| Build the full `CFG-006` backend-driven design now (`ADR-0007`) | Correct long-term target, but requires a new backend module, a DB migration, an API, and a client networking decision (the `guardian_core` gap) before a single string could render — too large and too coupled to ship a working bilingual app now. Not abandoned — see Reversal Cost. |
| Machine-translate Kannada now instead of leaving English fallback | Rejected per explicit direction: shipping unreviewed machine translation for safety-critical parent/driver-facing copy (wrong-bus alerts, handover overrides) is a real safety risk in this product, not a cosmetic one. An explicit, tracked gap is safer than a plausible-looking but unverified translation. |
| Skip `driver_attender_app` or `admin` for now, pilot in `parent_app` only | Rejected per explicit direction: all three real apps are in scope for this pass. |

## Consequences

**Positive**
- All three apps get a real, working locale-switching mechanism and complete English coverage now, with every string already keyed — the highest-cost part of a later migration to `CFG-006` (finding and extracting every literal) is done once, here.
- Kannada gaps are enumerable and reviewable (`TRANSLATION_STATUS.md` per app) instead of scattered `TODO`s in code, which `CLAUDE.md` §6 forbids.

**Negative / accepted cost**
- Client-bundled strings mean a copy change ships as an app release, not a config change — the opposite of what `ADR-0007` is designed to give tenants. Acceptable short-term; not acceptable as the permanent architecture.
- Three separate ARB trees (one per app repo) will need consolidating into `CFG-006` resource keys later; some key-naming drift between apps is likely and should be reconciled at that point, not preemptively unified now (unifying now would mean inventing a cross-app shared package this ADR explicitly did not scope).
- No automated lint/ArchUnit-equivalent enforcement yet that a new string literal doesn't sneak back in — regression relies on code review until that tooling is built.

**Neutral**
- `ADR-0007` remains the target architecture and is not superseded. This ADR is explicitly an interim step, not a redesign of it.

## Reversal Cost

Low for the mechanism, non-trivial for the content. When `CFG-006` is implemented, each app's `AppLocalizations` call sites do not need to change shape (`context.l10n.someKey(args)` either resolves locally or proxies to a backend-loaded map); the ARB files migrate into `localisation_resources` seed data essentially as-is. The Kannada gap must still be closed by a real translator regardless of which architecture is running — this ADR does not defer that cost, only where the values live in the meantime.

## Verification

1. Each app builds and runs with `flutter gen-l10n` succeeding and `flutter analyze` clean.
2. Switching the in-app locale control changes visible UI text immediately, without restart, in both `en` and `kn`.
3. A manual grep pass (documented per app) finds no remaining user-facing `Text('...')`/label/hint/tooltip string literal in `lib/` outside generated code.
4. `TRANSLATION_STATUS.md` in each app accounts for every resource key with no key silently missing from `app_kn.arb`.
