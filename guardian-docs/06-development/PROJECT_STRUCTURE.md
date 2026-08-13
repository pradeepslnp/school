# PROJECT STRUCTURE

**Document tier:** 6 — Development
**Status:** Active
**Implements:** [`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §1, §2

---

## Repository Layout

Each project is its own repository. They are **cloned side by side into one parent directory** — that is not a convenience, it is what makes a checkout build: the Flutter apps resolve `guardian_core` by relative path, and the backend's architecture tests read `guardian-docs` at `../../guardian-docs`.

```
guardian/
├── guardian-docs/                 tiers 0–8, plus INSTRUCTIONS.md,
│                                  PROJECT_CHARTER.md, *_PRINCIPLES.md,
│                                  AI_MASTER_PROMPT.md
├── guardian-backend/
│   ├── settings.gradle.kts
│   ├── build.gradle.kts           shared conventions
│   ├── guardian-common/           cross-cutting; NO business rules
│   ├── guardian-tenancy/          ← reference implementation
│   ├── guardian-identity/
│   └── guardian-api/              bootstrap, security, migrations
├── guardian-core/                 shared pure Dart — domain, network, design
├── guardian-parent-app/           Flutter
├── guardian-driver-app/           Flutter, offline-first (ADR-0008)
├── guardian-admin-web/            Flutter Web
└── guardian-infra/                docker-compose, db bootstrap
```

Modules are added per [`MODULE_MAP.md`](../01-product-discovery/MODULE_MAP.md). **`guardian-tenancy` is the pattern** — copy its structure, do not invent a new one.

### Cross-repository dependencies

Exactly three exist. Adding a fourth needs an ADR — the split is only worth its cost while the couplings stay countable.

| From | To | Mechanism |
|---|---|---|
| `guardian-parent-app`, `guardian-driver-app` | `guardian-core` | pub path dependency, `path: ../guardian-core` |
| `guardian-backend` (tests only) | `guardian-docs` | `DocsPath` resolves `../../guardian-docs`, overridable via `GUARDIAN_DOCS_PATH` |
| `guardian-backend` (run time) | `guardian-infra` | `docker compose -f ../guardian-infra/docker-compose.yml up -d` |

`guardian-admin-web` deliberately depends on nothing. It does not use `guardian_core` yet; when a screen needs shared domain types, add the same path dependency the apps use.

---

## Backend Module Layout

Every module is identical. **Package by feature, then by layer** — never `com.guardian.controllers`.

```
guardian-<module>/src/main/java/com/guardian/<module>/
├── domain/                    NO framework imports
│   ├── School.java                    entity
│   ├── SchoolCode.java                value object
│   ├── SchoolStatus.java              enum
│   └── SchoolDomainService.java       rules spanning entities
├── application/
│   ├── usecase/
│   │   ├── CreateSchoolUseCase.java   one class, one operation
│   │   └── GetSchoolUseCase.java
│   ├── port/
│   │   └── SchoolRepository.java      interface — infrastructure implements
│   └── command/
│       └── CreateSchoolCommand.java
├── infrastructure/
│   └── persistence/
│       ├── SchoolEntity.java          JPA — never leaves this package
│       ├── SchoolJpaRepository.java
│       ├── SchoolPersistenceMapper.java
│       └── SchoolRepositoryAdapter.java   implements the port
└── interfaces/
    └── rest/
        ├── SchoolController.java
        ├── dto/CreateSchoolRequest.java
        ├── dto/SchoolResponse.java
        └── SchoolDtoMapper.java
```

### The dependency rule

```
interfaces ──► application ──► domain
                    ▲
infrastructure ─────┘   (implements ports)
```

**Domain depends on nothing.** No Spring, no JPA, no HTTP types. Enforced by ArchUnit — see [`ARCHITECTURE_ENFORCEMENT.md`](ARCHITECTURE_ENFORCEMENT.md).

### Three models, deliberately

| Model | Layer | Purpose |
|---|---|---|
| `CreateSchoolRequest` | interfaces | Wire format; validation annotations |
| `School` | domain | Business rules; no framework |
| `SchoolEntity` | infrastructure | JPA mapping |

This is more code than a single annotated class. It is worth it here because safety records outlive ORM choices: retention, partitioning, and archival changes would otherwise ripple into domain rules ([`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §4).

**A JPA entity never leaves `infrastructure`. A domain object is never serialised to a client.**

---

## `guardian-common`

Cross-cutting only. **No business rules** — if a rule belongs here, it belongs in a module.

```
com.guardian.common/
├── tenant/         TenantContext, TenantContextFilter, transaction binding
├── audit/          AuditPort, AuditRecord — implemented in guardian-api
├── error/          DomainException hierarchy, ErrorCode
├── security/       permission annotations, scope resolution contracts
└── model/          shared value objects (Coordinates, TimeRange)
```

Every module may depend on it; it depends on no module.

---

## Use Cases

One class, one operation. If the name needs "And", split it.

```java
@Service
public class CreateSchoolUseCase {

    private final SchoolRepository schoolRepository;
    private final OrganizationRepository organizationRepository;
    private final AuditPort auditPort;

    public CreateSchoolUseCase(SchoolRepository schoolRepository,
                               OrganizationRepository organizationRepository,
                               AuditPort auditPort) {
        this.schoolRepository = schoolRepository;
        this.organizationRepository = organizationRepository;
        this.auditPort = auditPort;
    }

    @Transactional
    public School execute(CreateSchoolCommand command) {
        // 1. load, 2. enforce domain rules, 3. persist,
        // 4. audit IN THE SAME TRANSACTION (BR-AUD-002)
    }
}
```

**Constructor injection only.** No field injection, no `@Autowired` on fields, no static mutable state.

**The audit write shares the transaction** (BR-AUD-002 🔴) — if audit fails, the change rolls back.

---

## Ports and Adapters

```java
// application/port — speaks the domain's language, not the ORM's
public interface SchoolRepository {
    Optional<School> findById(SchoolId id);
    List<School> findActiveByOrganization(OrganizationId organizationId);
    School save(School school);
}
```

```java
// infrastructure/persistence
@Component
public class SchoolRepositoryAdapter implements SchoolRepository { … }
```

Method names describe intent (`findActiveByOrganization`), never mechanism (`findByOrgIdAndIsActiveTrue`).

---

## Flutter Layout

Feature-first, using the BLoC layering. **Every feature folder has the same five parts**, so a developer opening an unfamiliar feature already knows where everything is:

```
guardian_parent/lib/
├── main.dart
├── app/                          theme, config, top-level routing
└── features/
    └── login/
        ├── bloc/                 login_bloc.dart, login_event.dart, login_state.dart
        ├── ui/                   the screen — one route, owns the feature's wiring
        ├── widgets/              pieces used only by this feature
        ├── repository/           login_repository.dart + models/
        └── data_provider/        login_data_provider.dart — HTTP only
```

### What belongs in each layer

| Folder | Responsibility | Must not |
|---|---|---|
| `data_provider/` | Names endpoints and shapes payloads. Calls `RestClient`. | Import `package:http`, or interpret what a failure *means* |
| `repository/` | Turns transport into domain outcomes. Returns `Result<T>`, maps wire errors onto `ErrorCode`. | Import Flutter, or throw for an expected failure |
| `bloc/` | Every decision: what is submittable, what a failure means, when a retry is allowed. | Touch the data provider directly, or build widgets |
| `ui/` | The route. Composes data provider → repository → BLoC for the feature. | Contain business rules |
| `widgets/` | Renders state, emits events. | Decide anything |

The dependency direction is strictly one way:

```
ui / widgets  →  bloc  →  repository  →  data_provider
```

A widget that reaches past the BLoC to a repository, or a BLoC that reaches past its repository to a data provider, is a layering violation — the fake repository in `login_bloc_test.dart` throws from `dataProvider` specifically to catch that.

**Reference implementation:** `features/login/` in `guardian_parent`. New features copy its shape.

A feature without remote data (`home`, today) simply has no `data_provider/`, and gains one when it needs one. A feature with no decisions yet has no `bloc/`. Do not create empty folders to satisfy the pattern.

Shared models used by several features live in `guardian_core`; models used by one feature live in that feature's `repository/models/`.

### `core/network/` — the HTTP boundary

Each app has one `RestClient` (`lib/core/network/rest_client.dart`) and one `ApiResponse`. **Every network call goes through it**, so timeouts, headers, retry policy, and response decoding are decided once instead of per feature. A data provider that imports `package:http` directly bypasses all of it.

`RestClient` never throws for a network fault. Socket errors, timeouts, and unparseable replies all become `ApiResponse.transportFailure`, so a repository handles "no network" on the same path as "server said no" rather than wrapping every call in a try/catch.

**Retry policy is tied to safety, not convenience.** `GET`, `PUT`, and `DELETE` retry; `PATCH` does not; `POST` retries **only** when given an `idempotencyKey`. A retried `POST` that already succeeded records the action twice — for a boarding or handover event that means a child appears to board twice and trip-close reconciliation is wrong.

```
packages/guardian_core/lib/
├── api/          generated client, interceptors
├── models/       shared domain models
├── errors/       error types matching ERROR_CATALOG.md
├── auth/         token storage, refresh
└── design/       tokens, shared components
```

**`guardian_core`'s domain layers must not import `package:flutter/material.dart`** — a dependency test enforces this, keeping the domain portable if ADR-0003 is reversed.

**No business logic in widgets** ([`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §8). Widgets render state and emit intents.

---

## Test Layout

Tests mirror source packages.

```
src/test/java/com/guardian/tenancy/
├── domain/SchoolTest.java                          unit, no Spring
├── application/CreateSchoolUseCaseTest.java        unit, mocked ports
├── infrastructure/SchoolRepositoryAdapterIT.java   Testcontainers
├── interfaces/SchoolControllerTest.java            MockMvc
└── SchoolTenantIsolationIT.java                    RLS verification
```

Every module has a tenant-isolation integration test. See [`TEST_STRATEGY.md`](../07-testing/TEST_STRATEGY.md).

---

## Adding a Module

1. Add a row to [`MODULE_MAP.md`](../01-product-discovery/MODULE_MAP.md) and confirm no dependency cycle.
2. Create `guardian-<module>` and register it in `settings.gradle.kts`.
3. Create the four layer packages.
4. Add tables to [`guardian-docs/03-database/tables/`](../03-database/tables/) with a Flyway migration **including RLS in the same migration**.
5. Add features to [`FEATURE_INVENTORY.md`](../01-product-discovery/FEATURE_INVENTORY.md).
6. Add endpoints to an API document, each declaring a permission.
7. Write tests referencing business rule IDs.

Copy `guardian-tenancy`. Do not invent a different structure.

---

## Naming

| Kind | Pattern |
|---|---|
| Use case | `<Verb><Noun>UseCase` |
| Port | `<Noun>Repository`, `<Noun>Gateway` |
| Adapter | `<Noun>RepositoryAdapter` |
| Controller | `<Noun>Controller` |
| Request / Response DTO | `<Verb><Noun>Request` / `<Noun>Response` |
| JPA entity | `<Noun>Entity` |
| Domain exception | `<Problem>Exception` |
| Unit test | `<Class>Test` |
| Integration test | `<Class>IT` |
