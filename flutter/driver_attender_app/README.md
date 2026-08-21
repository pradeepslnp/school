# Guardian Driver & Attendant App

Flutter client for drivers and attendants — trip execution, verified boarding and alighting, guardian handover, and trip-close reconciliation.

**Offline-first** per [ADR-0008](../../documentation/00-governance/adr/ADR-0008-offline-first-driver-app.md). A vehicle loses signal routinely; a boarding scan that fails because of coverage would push staff back toward paper, which is the outcome the platform exists to replace. Boarding events are recorded locally and synced afterwards.

Product and UI specifications: [`documentation/05-ui/DRIVER_ATTENDANT_APP.md`](../../documentation/05-ui/DRIVER_ATTENDANT_APP.md).

---

## Prerequisites

Flutter 3.x stable, and **`guardian_theme` cloned beside this repository as part of the workspace**:

```
school/                            repository root
└── flutter/
    ├── driver_attender_app/       ← you are here
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

**Exercise the offline path on any change that touches boarding.** A feature verified only against a live API has been verified in the condition this app is least likely to run in.

---

## Structure

Feature-first with BLoC. Every feature folder has the same five parts:

```
lib/
├── main.dart
├── app/                  theme, config, top-level routing
└── features/<feature>/
    ├── bloc/             events in, states out
    ├── ui/               the screen — one route
    ├── widgets/          pieces used only by this feature
    ├── repository/       decides what a result means; owns the offline queue
    └── data_provider/    names endpoints; calls RestClient only
```

**No business logic in widgets.** Widgets render state and emit intents. Sync and conflict handling belong in the repository layer, never in a screen.

Full conventions: [`CODING_STANDARDS_FLUTTER.md`](../../documentation/06-development/CODING_STANDARDS_FLUTTER.md).
