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
./gradlew :guardian-api:bootRun
```

Flyway applies migrations on startup. The API listens on `http://localhost:8080`; OpenAPI at `/swagger-ui.html`.

### Configuration

`application-local.yml` is committed with local defaults. **Secrets never are.** Override via environment:

```bash
export GUARDIAN_DB_PASSWORD=…
export GUARDIAN_JWT_PRIVATE_KEY_PATH=…
```

A local RSA keypair is generated on first run into `backend/.local/` (gitignored) — no shared development signing key.

---

## 3. Seed Data

```bash
./gradlew :guardian-api:seedDevelopmentData
```

Creates a realistic dataset: **two organizations under different region profiles**, several schools, ~200 students with guardians, vehicles with documents at varying expiry, staff with credentials, routes and stops, and trips across several days including exceptions.

Two region profiles is deliberate — it exercises ADR-0007 continuously, so region-specific behaviour leaking into code surfaces during development rather than at the first international customer.

Development logins are printed on completion. They exist only in the `local` profile and are refused in any other.

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
