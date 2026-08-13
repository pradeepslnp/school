# ADR-0009: Flutter Flavor Configuration

Status: Accepted

## Context

The repository contains multiple Flutter applications (`guardian-driver-app`, `guardian-parent-app`, `guardian-admin-web`). Developers need a consistent way to run development and production-like builds locally and in CI.

## Decision

Adopt a two-flavor strategy for Flutter apps: `dev` and `prod`.

- Use the `--flavor` argument for platform builds and `--dart-define` to pass build-time configuration.
- The following `dart-define` keys will be used:
  - `ENVIRONMENT` — canonical environment name (`dev` or `production`).
  - `API_BASE_URL` — runtime API base URL.

Android: add `flavorDimensions "env"` and `productFlavors { dev, prod }` to `android/app/build.gradle(.kts)` and provide `app_name` resources under `app/src/dev` and `app/src/prod`.

iOS: create build configurations and schemes for `dev` and `prod` and ensure Info.plist or bundle identifiers are configured per flavor.

VS Code: provide workspace `launch.json` entries to run each app with the appropriate `--flavor` and `--dart-define` values.

## Consequences

- Developers can run `flutter run --flavor dev --dart-define=ENVIRONMENT=dev` locally.
- CI and release pipelines must set `ENVIRONMENT` and `API_BASE_URL` explicitly for non-dev builds.
- The repo now includes `android/app/src/{dev,prod}/res/values/strings.xml` for Android apps and updated `launch.json`.

## Implementation Notes

- `ENVIRONMENT` is read by `AppConfig.fromEnvironment()` to determine `isProduction`.
- Default `API_BASE_URL` for dev is `http://localhost:8080/api/v1`.
- Production `API_BASE_URL` placeholder: `https://api.guardian.example/api/v1` — replace with real endpoints during release preparation.
