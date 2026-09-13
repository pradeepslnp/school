# FLUTTER CODING STANDARDS

**Document tier:** 6 — Development
**Stack:** Flutter 3.x, Dart 3.x · **Clients:** parent app, driver app, admin web

---

## Layering

Feature-first, mirroring the backend ([`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)):

```
features/<feature>/
├── bloc/            events in, states out — every decision lives here
├── ui/              the screen; composes the feature's dependencies
├── widgets/         feature-local pieces; render state, emit events
├── repository/      Result<T> outcomes + models/ — NO Flutter imports
└── data_provider/   HTTP only — no interpretation
```

Dependencies point one way: `ui / widgets → bloc → repository → data_provider`. Full responsibilities table in [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md).

**State management is `flutter_bloc`.** One `Bloc` per feature, `sealed` events and a single state class.

```dart
// Events are what the user did — never what the app should do.
final class LoginOtpSubmitted extends LoginEvent { … }   // right
final class ShowLoginError extends LoginEvent { … }      // wrong — UI issuing orders
```

An event named `Show…` or `Navigate…` means the decision moved back into the widget.

Blocs depend on a **repository**, never a data provider — that is what lets a bloc test run with no HTTP, no fake server, and an injected clock instead of real waiting. See `test/features/login/login_bloc_test.dart`.

**No business logic in widgets** ([`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §8). Widgets render state and emit intents.

```dart
// wrong — a business rule evaluated in a widget
if (student.boardedAt != null && student.alightedAt == null) {
  showCriticalAlert();
}

// right — the decision belongs to the domain
if (state.hasUnaccountedStudents) {
  showCriticalAlert();
}
```

A rule checked in the UI is checked **for user experience only**. The server decides (BR-IAM-001).

---

## `guardian_core`

Shared across all three clients. Its domain layers **must not import `package:flutter/material.dart`** — enforced by a dependency test.

This keeps the domain portable if ADR-0003 is reversed and the admin console is rebuilt in React. The design layer is separate from the domain layer for exactly this reason.

---

## Immutability

All models immutable, with `copyWith`, value equality, and exhaustive `fromJson`/`toJson`.

State classes are immutable and describe the whole screen state, including loading and error:

```dart
sealed class TripState {}
final class TripLoading extends TripState {}
final class TripLoaded extends TripState {
  final Trip trip;
  final List<ManifestEntry> manifest;
  final SyncStatus syncStatus;
  const TripLoaded({required this.trip, required this.manifest, required this.syncStatus});
}
final class TripError extends TripState {
  final ErrorCode code;      // never a raw string
  const TripError(this.code);
}
```

Sealed classes force every state to be handled — a missing case is a compile error, not a blank screen.

---

## Null Safety

Sound null safety throughout. **No `!` on values that can genuinely be null** — handle absence explicitly. `late` only where initialisation is provably guaranteed.

---

## Errors

Domain results are typed. `ErrorCode` mirrors [`ERROR_CATALOG.md`](../04-api/ERROR_CATALOG.md).

```dart
sealed class Result<T> {}
final class Success<T> extends Result<T> { final T value; }
final class Failure<T> extends Result<T> { final ErrorCode code; final String? detail; }
```

The UI renders the **localised `messageKey`** returned by the API, never a raw code and never an internal detail.

---

## Localisation

**No user-facing string literal in any widget** (BR-CFG-005) — enforced by a lint and an architecture test.

```dart
Text(context.l10n.studentBoardedAt(student.name, time))   // yes
Text('${student.name} boarded at $time')                  // no
```

Layouts tolerate ±40% string length; no fixed-width text containers. Full RTL with logical start/end rather than left/right. Dates, times, and numbers formatted per locale (ADR-0007).

**All times render in the school's timezone** (BR-CFG-006), never the device's — a parent travelling abroad must still see school-local times.

---

## Networking

All API access through `guardian_core`'s generated client. Interceptors handle auth, refresh, correlation ID, and retry.

- Every request carries a timeout.
- Token refresh is transparent and single-flight — concurrent 401s must not trigger parallel refreshes.
- Certificate pinning on both mobile apps.
- **Retries carry the same idempotency key** (BR-BOARD-009). A retried boarding submission must not create a second record.

---

## Offline — Driver App Only (ADR-0008)

```dart
Future<void> recordBoarding(BoardingEvent event) async {
  await _localStore.insert(event);        // 1. local first
  _ui.confirm(event);                      // 2. immediate feedback
  unawaited(_syncQueue.enqueue(event));    // 3. sync in background
}
```

**The UI is never blocked on a network call for a safety action.** A child does not wait for a spinner.

Rules:
- Local store is **encrypted**; wiped on logout and on remote session revocation.
- Every record carries a client-generated UUID for idempotency.
- The queue survives app restart and device reboot.
- `occurredAt` (device clock) and measured clock skew are both recorded — the device clock is never authoritative (BR-BOARD-008).
- **Pending-sync count is always visible.** Silent queuing hides failure from the person who most needs to know.

**The parent app is not offline-first.** It is a read surface; stale data there is a display problem, not data loss.

---

## Performance

- `const` constructors wherever possible.
- Long lists always use `ListView.builder`; admin grids are virtualised.
- Images cached and correctly sized; student photos load through the authorising endpoint.
- No expensive work in `build()`.
- Live updates arrive via WebSocket, not polling — polling at the freshness target drains phone batteries.

Admin web tracks a load budget in CI; a sustained breach reopens ADR-0003 ([`ADMIN_WEB.md`](../05-ui/ADMIN_WEB.md)).

---

## Accessibility

Non-negotiable ([`ACCESSIBILITY.md`](../05-ui/ACCESSIBILITY.md)):

- `Semantics` on every custom component; `excludeSemantics` on decorative layers.
- Custom-painted elements carry semantic labels — a canvas marker is invisible to a screen reader otherwise.
- Touch targets: 48 px parent, **64 px driver**, 88 px SOS.
- Text scales to 200% without loss of function.
- Critical alerts use assertive live regions.
- Motion respects `prefers-reduced-motion`.

---

## Security

- Tokens in platform secure storage, never in shared preferences. **One recorded exception:** the `admin` web console persists its session in `localStorage` and re-validates it against the server on every restore — [ADR-0015](../00-governance/adr/ADR-0015-admin-web-session-persistence.md) states the accepted risk and the exit. The exception is scoped to that client; it is not precedent for the parent or driver apps, where secure storage is actually available.
- Screenshots suppressed on screens showing child personal data.
- No child data in device logs.
- Certificate pinning on mobile.
- Local store encrypted and wiped on logout.

---

## Testing

| Level | Scope |
|---|---|
| Unit | Domain logic and state notifiers, no widgets |
| Widget | Screens including empty, loading, and error states |
| Golden | Key screens in light and dark, LTR and RTL |
| Integration | Critical journeys, including a full offline trip |

Every screen's three states are tested — an untested error state becomes a blank screen in production.

---

## Analysis

`flutter analyze` clean, with a strict lint set: `prefer_const_constructors`, `avoid_print`, `always_declare_return_types`, `require_trailing_commas`, plus custom lints for hardcoded user-facing strings and business logic in widgets.

Warnings are errors in CI.

---

## Checklist Before Merge

- [ ] No business logic in widgets
- [ ] No user-facing string literals
- [ ] Empty, loading, and error states defined and tested
- [ ] Times rendered in the school's timezone
- [ ] Live data carries a freshness indicator
- [ ] Touch targets meet the per-client minimum
- [ ] Semantics on custom components
- [ ] Offline path tested (driver app)
- [ ] Idempotency key on retried writes
- [ ] `flutter analyze` clean
