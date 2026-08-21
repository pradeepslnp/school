# Guardian Admin Web

Flutter Web console for school and platform administration — organisations, schools, students and guardians, vehicles and documents, staff, routes, and audit review.

Product and UI specifications: [`documentation/05-ui/ADMIN_WEB.md`](../documentation/05-ui/ADMIN_WEB.md).

---

## Why Flutter for a web console

[ADR-0003](../documentation/00-governance/adr/ADR-0003-admin-web-client.md) chose Flutter to keep one language and one domain layer across all three clients, on an explicit condition: the decision stays **reversible**. Shared meaning lives in `guardian_core` (pure Dart), so a React console would replace the view layer only.

The ADR also sets a load budget for this console. A sustained breach reopens the decision rather than being absorbed — see the accessibility and performance checks in [`08-deployment/CI_CD.md`](../documentation/08-deployment/CI_CD.md).

---

## Run

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Start the API from `backend` first.

```bash
flutter analyze    # warnings are errors
flutter test
```

This repository has **no cross-repository dependencies** — it builds from a standalone clone. It does not use `guardian_core` yet; when a screen needs shared domain types, add the path dependency the mobile apps use:

```yaml
guardian_core:
  path: ../guardian-core
```

That makes `guardian-core` a required sibling checkout, so add it when a screen actually needs it, not in advance.

---

## What is built

The console's foundation and staff sign-in. No operational screen is implemented yet.

```
lib/
├── main.dart                  bootstrap, then the app
├── app/
│   ├── app_config.dart        --dart-define configuration
│   ├── theme.dart             design tokens (DESIGN_SYSTEM.md)
│   ├── dependencies.dart      composition root + DependencyScope
│   ├── admin_app.dart         MaterialApp.router
│   └── console_router.dart    Navigator 2.0, keyed on auth status
├── core/
│   ├── domain.dart            Result<T>, ErrorCode (ERROR_CATALOG.md)
│   ├── network/               RestClient, ApiResponse — the one HTTP boundary
│   └── session/               Session, SessionStore, SessionManager
└── features/
    ├── login/                 bloc · ui · widgets · repository · data_provider
    └── shell/                 the authenticated frame and its navigation
```

Layering follows [`PROJECT_STRUCTURE.md`](../documentation/06-development/PROJECT_STRUCTURE.md) §Flutter Layout: `ui / widgets → bloc → repository → data_provider`, one way only.

Two structural differences from the mobile apps, both forced by the browser:

- **`core/network/rest_client.dart` imports no `dart:io`.** A web build cannot. Browser-level faults arrive as `http.ClientException` and become `ApiResponse.transportFailure`, as they do on mobile.
- **Routing is derived from the session, not from a route table.** `ConsoleRouterDelegate` listens to `SessionManager`, so a revoked session (BR-IAM-007) cannot leave a screen holding child data mounted. There is no routing package; see the note in `pubspec.yaml`.

Sign-in is `POST /auth/login` with `clientType: ADMIN_WEB`, exactly as specified in [`AUTHENTICATION_API.md`](../documentation/04-api/AUTHENTICATION_API.md).

---

## Known gaps

These are stated rather than worked around. Each needs a decision, not a client-side patch.

| Gap | Effect | Where it is resolved |
|---|---|---|
| No CORS policy on `backend` | A browser refuses every request from this console before it is sent, reported as `ApiResponse.transportFailure` | Resolved — `guardian-api`'s `CorsConfig` + `SecurityConfig`, origins from `guardian.web.allowed-origins` |
| `POST /auth/login` was not implemented in `backend` | Sign-in reported the API as unreachable | Resolved — `StaffLoginUseCase`, `auth_resolve_email` (V10 migration), demo account seeded in `V900__demo_data.sql` (`anil@demo-trust.example` / `Guardian!Demo2026`) |
| No staff-provisioning screen or API | ~~A staff account can only be created by hand-inserting a `user_credentials` row, as the demo seed does~~ | Resolved — A-23 Drivers screen (`features/staff`), backed by `CreateTransportStaffUseCase` provisioning a driver-app sign-in (phone + OTP) in the same request as the roster record. `schoolId` is a plain field, not a picker: there is still no schools-list screen for it to draw from |
| No second factor | [`SECURITY_ARCHITECTURE.md`](../documentation/02-system-design/SECURITY_ARCHITECTURE.md) requires *password + second factor* for admin web; `AUTHENTICATION_API.md` documents no challenge step. The higher-tier document wins | The API document needs the challenge/response shape before either side can build it |
| The session does not survive a page reload | An operator signs in again after every refresh | `InMemorySessionStore` is deliberate — web storage is readable by any script on the origin. The fix is an `HttpOnly` refresh cookie set by the API, which changes a documented contract and so needs an ADR |
| URLs are hash-based (`/#/sign-in`) | Cosmetic | `usePathUrlStrategy()` plus a catch-all rewrite to `index.html` in `infrastructure` |
| User-facing strings are literals | Fails BR-CFG-005 | No client has `flutter_localizations` yet; resolve all three together. `messageKey` is already carried end to end |

No new Flutter test classes were added, per the current exception in [`INSTRUCTIONS.md`](../documentation/INSTRUCTIONS.md#current-exception--flutter-tests).
