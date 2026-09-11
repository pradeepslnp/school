# LOCAL SETUP

**Document tier:** 6 — Development
**Status:** Active

---

## Prerequisites

| Tool | Version |
|---|---|
| JDK | 21 (Temurin recommended) |
| Docker + Compose | current |
| Flutter | 3.x stable |
| Git | 2.40+ |

Verify: `java -version` · `docker compose version` · `flutter doctor`

---

## 0. Clone

Every command below runs from a parent directory holding **all seven repositories side by side**. The layout is load-bearing — see [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md#cross-repository-dependencies) for the three couplings that rely on it.

```bash
mkdir guardian && cd guardian
for r in docs backend core parent-app driver-app admin-web infra; do
  git clone https://github.com/pradeepslnp/guardian-$r.git
done
```

---

## 1. Infrastructure

```bash
docker compose -f infrastructure/docker-compose.yml up -d
docker compose -f infrastructure/docker-compose.yml ps
```

Starts PostgreSQL 16 (`localhost:5432`) and Redis 7 (`localhost:6379`).

### Database roles

`infrastructure/db/init/01-roles.sql` runs on first start and creates the two roles that make RLS meaningful ([`RLS_POLICIES.md`](../03-database/RLS_POLICIES.md)):

| Role | Purpose |
|---|---|
| `guardian_owner` | Owns schema objects; used by Flyway only |
| `guardian_app` | Application runtime. **`NOBYPASSRLS`, not the owner.** |

**Do not run the application as `guardian_owner`.** RLS is `FORCE`d, but running as owner defeats the point of having a separate runtime role and hides isolation bugs until production.

---

## 2. Backend

```bash
cd backend
./gradlew build          # compile + unit + architecture tests

SPRING_PROFILES_ACTIVE=demo \
GUARDIAN_DB_MIGRATION_PASSWORD=local_owner \
GUARDIAN_DB_PASSWORD=local_app \
./gradlew :guardian-api:bootRun
```

Flyway applies migrations on startup. The API listens on `http://localhost:8080`; OpenAPI at `/swagger-ui.html`.

### The `demo` profile

**`SPRING_PROFILES_ACTIVE=demo` is not optional for a usable local backend.** It is the only thing that adds `classpath:db/seed` to `spring.flyway.locations` (`application-demo.yml`), and without it Flyway runs `db/migration` only — an empty schema with no accounts, so nothing can sign in. The profile also sets the fixed OTP (`123123`) and raises the OTP/email logger so codes and links are readable in the log. It is refused structurally by any deployment that does not name it.

### Configuration

Local defaults live in `application.yml` itself; there is no `application-local.yml`. **Secrets never are committed.** The two database passwords above match `infrastructure/db/init/01-roles.sql` (`local_app`) and the compose default (`local_owner`); override anything via environment, e.g. `GUARDIAN_DB_PASSWORD`, `GUARDIAN_PORT`.

The JWT signing key is **ephemeral in development** — generated per run, with a startup warning; every restart invalidates outstanding tokens. A real key (`guardian.security.jwt.private-key`) is required only under the `prod`/`production` profile.

---

## 3. Seed Data

There is no separate seed command — the `demo` profile applies it. On top of the schema, Flyway runs:

- **`V900__demo_data.sql`** — the parent- and driver-app fixtures (phone `8050602046`, OTP `123123`) plus two console accounts on `.example` addresses.
- **`V901__role_login_accounts.sql`** — one admin-console login per role, on real Gmail addresses, so each role's authorisation can be exercised.

Console logins, password **`Guardian!Demo2026`** for all:

| Email | Role |
|---|---|
| `pradeepslnp7@gmail.com` | `SUPER_ADMIN` |
| `pradeepslnp07@gmail.com` | `ORG_ADMIN` |
| `akshay5632@gmail.com` | `SCHOOL_ADMIN` |
| `reelsatdesk@gmail.com` | `PRINCIPAL` |
| `7625055445l@gmail.com` | `TRANSPORT_MANAGER` |

Self-service password reset (`/forgot-password`) and the invitation set-password flow both work locally: on the `demo` profile the emailed 6-digit reset code is always `123123`, and — with no mail host configured (below) — the invite link is written to the backend log rather than sent.

---

## 3a. Email (invitation / reset) — optional

By default account-lifecycle email is written to the log (`LoggingAccountEmailSender`). To send it for real in development (ADR-0014), run a local catcher and point the backend at it:

```bash
docker run -d --name guardian-mailhog -p 1025:1025 -p 8025:8025 mailhog/mailhog
# then add to the bootRun environment:
SPRING_MAIL_HOST=127.0.0.1 GUARDIAN_SMTP_PORT=1025
```

Mail then appears at `http://localhost:8025`. For a real relay (Google Workspace / Gmail):

```bash
SPRING_MAIL_HOST=smtp.gmail.com
GUARDIAN_SMTP_PORT=587
GUARDIAN_SMTP_USERNAME=no-reply@yourdomain.com
GUARDIAN_SMTP_PASSWORD=<16-char app password>     # not the account password
GUARDIAN_EMAIL_FROM=Guardian Platform <no-reply@yourdomain.com>
```

With `SPRING_MAIL_HOST` set, real delivery takes over automatically. Under `prod`/`production` it is mandatory — the context fails to start without it.

---

## 4. Flutter Clients

```bash
cd guardian-core       && dart pub get    && dart test
cd ../flutter/parent_app && flutter pub get && flutter run
cd ../flutter/driver_attender_app && flutter pub get && flutter run
cd ../admin  && flutter pub get && flutter run -d chrome
```

Point clients at the local API:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Android emulator uses `http://10.0.2.2:8080`; a physical device needs your machine's LAN address.

**parent_app's P-04 Live Trip Map** needs a Google Maps API key, per platform, never committed (CLAUDE.md §7):

```bash
# Android — one of:
export MAPS_API_KEY=<your key>                        # picked up by app/build.gradle.kts
echo "MAPS_API_KEY=<your key>" >> flutter/parent_app/android/local.properties   # already gitignored

# iOS
cp flutter/parent_app/ios/Flutter/Secrets.xcconfig.example flutter/parent_app/ios/Flutter/Secrets.xcconfig
# then edit Secrets.xcconfig and fill in MAPS_API_KEY=<your key>
```

Without a key the app still builds and runs — P-04's text summary is complete either way (docs/05-ui/PARENT_APP.md); the map beneath it just renders no tiles.

---

## 5. Tests

```bash
cd backend
./gradlew test                    # unit + architecture
./gradlew integrationTest         # Testcontainers — Docker must be running
./gradlew check                   # everything, including Spotless
```

The architecture tests read `BUSINESS_RULES.md` and `PERMISSION_MATRIX.md` out of `documentation`, resolved at `../../documentation`. If that repository is checked out elsewhere, point at it explicitly rather than copying the files:

```bash
GUARDIAN_DOCS_PATH=/path/to/documentation ./gradlew test
```

They fail rather than skip when the documentation is missing — a traceability test that passes without reading the rules would certify nothing.

Integration tests start their own PostgreSQL container. **They do not use your development database** — they create and drop schemas, and pointing them at a shared database would destroy your seed data.

```bash
cd flutter/parent_app && flutter test
```

---

## Common Problems

**Migrations fail on startup.** The container was likely created before `init/` scripts existed. Reset:
```bash
docker compose -f infrastructure/docker-compose.yml down -v
docker compose -f infrastructure/docker-compose.yml up -d
```
`-v` deletes the volume. Local data only.

**Queries return no rows even though data exists.** Almost always RLS with no tenant context set — the correct, safe failure ([`MULTI_TENANCY.md`](../02-system-design/MULTI_TENANCY.md)). Check that the request carries a valid token, or that a job sets context per tenant.

Inspecting data directly:
```sql
-- as guardian_owner, in a psql session
SET app.tenant_id = '<organization uuid>';
SELECT * FROM students;
```
Use `SET LOCAL` in application code — never plain `SET`. Session-scoped setting leaks across pooled connections.

**Live tracking is empty.** Positions only exist during an active trip (BR-TRACK-001). Start a trip from the seeded data, or run the position simulator:
```bash
./gradlew :guardian-api:simulatePositions --args="--tripId=<uuid>"
```

**Flutter cannot reach the API.** Check `API_BASE_URL`, and use `10.0.2.2` on the Android emulator rather than `localhost`.

**Architecture tests fail after adding a class.** They are working. See [`ARCHITECTURE_ENFORCEMENT.md`](ARCHITECTURE_ENFORCEMENT.md) — the fix is usually to move the class, not to change the rule. Never disable the test.

---

## Useful Commands

```bash
docker compose -f infrastructure/docker-compose.yml logs -f postgres
docker compose -f infrastructure/docker-compose.yml exec postgres psql -U guardian_owner -d guardian
./gradlew :guardian-api:flywayInfo
./gradlew spotlessApply
./gradlew dependencyUpdates
```

---

## Before Your First Commit

Read, in order: [`INSTRUCTIONS.md`](../INSTRUCTIONS.md) · [`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) · [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md) · [`DEFINITION_OF_DONE.md`](DEFINITION_OF_DONE.md).

Then open [`guardian-tenancy`](../../backend/guardian-tenancy/) — it is the reference implementation, and every other module follows it.
