# Flutter App Instructions

**Document tier:** 1 — Implementation guidance
**Status:** Active

---

## Purpose

This document provides explicit, reusable instructions and a prompt-template for developers and AI agents when working on the Flutter applications in this repository (driver, parent, admin web client). It complements `INSTRUCTIONS.md` and focuses on Flutter-specific architecture, conventions, and safety rules.

## Key Principles (Flutter-specific)

- Keep business logic out of widgets — place it in services, providers, or domain classes.
- Follow the repository `ENGINEERING_PRINCIPLES.md` (Clean Architecture, SOLID, DI, modular features).
- No placeholder or pseudo-production code in UI surfaces.
- Prefer configuration over hardcoding for environment or tenant-specific behaviour.
- Keep widget trees thin; expose state through well-defined interfaces.
- Run `flutter analyze` and preserve existing Flutter tests; do not add new widget tests unless requested.

## Developer Checklist

- Confirm which Flutter project is affected (`flutter/driver_attender_app`, `flutter/parent_app`, `admin`).
- Identify which package(s) in `/lib` will change and whether `guardian_core` is impacted.
- List API and database impacts, and create or update API contract docs if backend changes are required.
- Add or update the relevant ADR when introducing architectural changes.
- Run `flutter analyze` and ensure no new analyzer issues are introduced.

## How to Use This Document (AI & Humans)

First size the task using `INSTRUCTIONS.md` STEP 0. For a **Trivial** change (typo, small widget-local bug fix, copy/config change) just make the change and explain it in 1–2 lines — the checklist and plan below are for Standard/Architectural tier work.

For Standard or Architectural tasks: follow the steps in `INSTRUCTIONS.md` first, then apply the Flutter checklist above. Before producing code, provide a brief plan covering:

1. Requirement summary
2. Documents referenced
3. Business rules applied
4. Proposed solution and architecture changes
5. Impact analysis (API, DB, UI, security, testing)

Only after that produce code following the project's standards.

## Prompt Template — Adopt Repository Architecture (use when asking an AI to write Flutter code)

Use the following prompt when requesting changes from an AI, replacing bracketed values:

"You are an expert developer contributing to the Guardian Platform. Before writing code, read and follow `documentation/INSTRUCTIONS.md` and `documentation/FLUTTER_APP_INSTRUCTIONS.md`. The project follows Clean Architecture, SOLID, and separates UI from business logic. The target project is [PROJECT_NAME] (path: [PROJECT_PATH]).

Requirement: [SHORT_REQUIREMENT].

Explain the approach (architecture, modules to change), business impact, API and DB impact, UI changes, security considerations, and testing plan. Then produce the minimal, production-quality code changes required, avoiding placeholders and pseudo-production code. Ensure `flutter analyze` remains clean and do not add new widget tests unless explicitly requested."

## Files to Update for New Features

- Add ADRs under `documentation/00-governance/adr/` for architectural decisions.
- Update `MODULE_MAP.md` and `FEATURE_INVENTORY.md` when features are added or changed.

## When to Ask Questions

If an API contract, permission, or business rule is missing or ambiguous, ask clarifying questions before coding.

---

End of document.

## Flavor Setup (DEV / PROD)

This repository provides preconfigured VS Code launch configurations that run each Flutter app with a `dev` or `prod` flavor. See `.vscode/launch.json` at the workspace root for the available configurations.

How the launch configs work

- Each launch configuration runs `lib/main.dart` in the target project folder with `--flavor` and a `--dart-define=ENVIRONMENT` so code can branch at runtime.
- Example args shown in launch configurations: `--flavor dev --dart-define=ENVIRONMENT=dev`.

Platform notes — additional setup required

Android

- Add product flavors to `android/app/build.gradle` inside each Flutter app (example):

```groovy
android {
	flavorDimensions "env"
	productFlavors {
		dev {
			dimension "env"
			applicationIdSuffix ".dev"
			resValue "string", "app_name", "Guardian (DEV)"
		}
		prod {
			dimension "env"
			resValue "string", "app_name", "Guardian"
		}
	}
}
```

You'll also need to create appropriate environment-specific resources under `app/src/dev` and `app/src/prod` if required by your services.

iOS

- Create iOS schemes named `Dev` and `Prod` with corresponding build configurations such as `Debug-dev`, `Release-dev`, `Debug-prod`, and `Release-prod`. Add flavor-specific Info.plist entries or bundle identifiers as needed.

Web

- Web builds use `--dart-define`; the launch configs pass `ENVIRONMENT` via `--dart-define` so you can read `const String.fromEnvironment('ENVIRONMENT')` in Dart.

Runtime usage examples (CLI)

Run a single app in DEV from the workspace root:

```bash
cd flutter/driver_attender_app
flutter run --flavor dev --dart-define=ENVIRONMENT=dev --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Run all three DEV configs via VS Code: open the Run and Debug view and choose `Run All (DEV)`.

If you want, I can also add example `android/app/src/dev` and `android/app/src/prod` resource folders and minimal iOS scheme instructions for each Flutter project — should I proceed?
