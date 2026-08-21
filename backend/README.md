# Guardian Backend

Spring Boot API for the Guardian Platform — multi-tenant student safety and transport. Gradle multi-module, Java 21.

Part of a seven-repository platform. See [`documentation`](https://github.com/pradeepslnp/guardian-docs) for the full picture; this README covers only what you need to build and run this service.

---

## Modules

| Module | Contents |
|---|---|
| `guardian-common` | Tenant context, error hierarchy, audit port, permission annotations. **No business rules** — if a rule belongs here, it belongs in a module. |
| `guardian-tenancy` | Organisations and schools. **The reference implementation** — new modules copy its structure. |
| `guardian-identity` | Users, roles, permissions |
| `guardian-api` | Bootstrap, security config, Flyway migrations |

Layering is `interfaces → application → domain`, with `infrastructure` implementing ports. Domain depends on nothing — no Spring, no JPA, no HTTP types. ArchUnit enforces this; the tests are not advisory.

---

## Prerequisites

JDK 21 (Temurin recommended), Docker, and two sibling folders checked out beside this one at the repository root:

```
school/                 repository root
├── backend/            ← you are here
├── documentation/       required by the architecture tests
└── infrastructure/      PostgreSQL + Redis for local development
```

`documentation` is a real build dependency, not a convenience. `BusinessRuleTraceabilityTest` and `EndpointPermissionTest` parse `BUSINESS_RULES.md` and `PERMISSION_MATRIX.md` to prove every documented rule has a test and every endpoint declares a known permission. They **fail** rather than skip when the documentation is absent — a traceability test that passes without reading the rules certifies nothing.

Checked out elsewhere? Point at it rather than copying the files:

```bash
GUARDIAN_DOCS_PATH=/path/to/documentation ./gradlew test
```

---

## Build and run

```bash
# 1. Start PostgreSQL and Redis
docker compose -f ../infrastructure/docker-compose.yml up -d

# 2. Compile, unit tests, architecture tests
./gradlew build

# 3. Run — Flyway applies migrations on startup
./gradlew :guardian-api:bootRun
```

The API listens on `http://localhost:8080`; OpenAPI at `/swagger-ui.html`.

### Tests

```bash
./gradlew test               # unit + architecture
./gradlew integrationTest    # Testcontainers — Docker must be running
./gradlew check              # everything, including Spotless
```

Integration tests start their own PostgreSQL container and create and drop schemas. They never touch your development database.

---

## Configuration

Secrets are never committed. Every credential is externalised with an empty default, so a missing value fails loudly at startup rather than silently falling back to something shared:

```bash
export GUARDIAN_DB_PASSWORD=…
export GUARDIAN_JWT_PRIVATE_KEY_PATH=…
```

A local RSA keypair is generated on first run into `.local/` (gitignored) — there is no shared development signing key.

**Do not run the application as `guardian_owner`.** That role exists for Flyway. The runtime role `guardian_app` is `NOBYPASSRLS` by design; running as owner defeats row-level security and hides isolation bugs until production.

---

## Further reading

Everything below lives in `documentation`:

- [`06-development/PROJECT_STRUCTURE.md`](../documentation/06-development/PROJECT_STRUCTURE.md) — module layout and the dependency rule
- [`06-development/ARCHITECTURE_ENFORCEMENT.md`](../documentation/06-development/ARCHITECTURE_ENFORCEMENT.md) — what the ArchUnit tests check and why
- [`02-system-design/MULTI_TENANCY.md`](../documentation/02-system-design/MULTI_TENANCY.md) — tenant isolation model
- [`03-database/RLS_POLICIES.md`](../documentation/03-database/RLS_POLICIES.md) — row-level security
- [`04-api/`](../documentation/04-api/) — endpoint contracts and error catalogue
