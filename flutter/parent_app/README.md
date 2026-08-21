# Guardian Parent App

Flutter client for parents and guardians — live vehicle tracking, boarding and alighting notifications, and handover confirmation for their own children.

Part of the Guardian Platform. Product and UI specifications live in [`documentation/05-ui/PARENT_APP.md`](../../documentation/05-ui/PARENT_APP.md).

---

## Prerequisites

Flutter 3.x stable, and **`guardian_theme` cloned beside this repository as part of the workspace**:

```
school/                            repository root
└── flutter/
    ├── parent_app/                ← you are here
    └── shared_packages/
        └── guardian_theme/        shared design tokens & theme (pure Dart)
```

`pubspec.yaml` resolves `guardian_theme` by relative path (`path: ../shared_packages/guardian_theme`), so `flutter pub get` fails without it present in the workspace. See [`PROJECT_STRUCTURE.md`](../../documentation/06-development/PROJECT_STRUCTURE.md#cross-repository-dependencies).

---

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

The Android emulator reaches the host at `10.0.2.2`, not `localhost`; a physical device needs your machine's LAN address. Start the API from `backend` first.

```bash
flutter analyze    # warnings are errors
flutter test
```

---

## Structure

Feature-first with BLoC. Every feature folder has the same five parts, so an unfamiliar feature is still navigable:

```
lib/
├── main.dart
├── app/                  theme, config, top-level routing
└── features/<feature>/
    ├── bloc/             events in, states out
    ├── ui/               the screen — one route
    ├── widgets/          pieces used only by this feature
    ├── repository/       decides what a result means
    └── data_provider/    names endpoints; calls RestClient only
```

**No business logic in widgets.** Widgets render state and emit intents; decisions belong in the BLoC or below. A data provider never imports `package:http` directly — transport concerns stay in `RestClient` inside `guardian_core`, so timeouts, headers, and retries are decided once.

Full conventions: [`CODING_STANDARDS_FLUTTER.md`](../../documentation/06-development/CODING_STANDARDS_FLUTTER.md).
