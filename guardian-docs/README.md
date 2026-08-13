# Guardian Platform — Documentation

A multi-tenant **student safety and transport platform** for schools — vehicle tracking, verified boarding and guardian handover, real-time parent notification, and an auditable record of every child's journey between home and school.

This repository holds the documentation for the whole platform. The code lives in six sibling repositories.

> **Documentation is the source of truth.** Read [`INSTRUCTIONS.md`](INSTRUCTIONS.md) before contributing anything, including AI-generated changes.

---

## Repositories

Clone all of them into **one parent directory**. The Flutter apps depend on `guardian-core` by relative path, and the backend's architecture tests read this repository from `../../guardian-docs`, so the layout below is what makes a checkout build.

```
guardian/
├── guardian-docs/          ← you are here — tiers 0–8
├── guardian-backend/       Spring Boot, Gradle multi-module, Java 21
├── guardian-core/          Shared pure-Dart domain layer
├── guardian-parent-app/    Flutter — parent app
├── guardian-driver-app/    Flutter — driver & attendant app
├── guardian-admin-web/     Flutter Web — school & platform administration
└── guardian-infra/         docker-compose, database bootstrap
```

| Repository | Contents | Depends on |
|---|---|---|
| `guardian-backend` | `guardian-common` (tenant context, errors, audit, arch tests), `guardian-tenancy` (reference vertical slice), `guardian-identity`, `guardian-api` (bootstrap, security, migrations) | `guardian-docs` at test time, `guardian-infra` at run time |
| `guardian-core` | Networking, DI, errors, shared models. Pure Dart by design (ADR-0003) | — |
| `guardian-parent-app` | Parent and guardian client | `guardian-core` |
| `guardian-driver-app` | Driver and attendant client, offline-first (ADR-0008) | `guardian-core` |
| `guardian-admin-web` | Administration console | — |
| `guardian-infra` | PostgreSQL 16 + Redis 7 for local development | — |

`guardian-tenancy` is the **reference implementation**. New backend modules copy its structure: `domain/` → `application/` → `infrastructure/` → `interfaces/`.

---

## Reading Order

**Start here (governance)**

| # | Document | What it settles |
|---|---|---|
| 1 | [`INSTRUCTIONS.md`](INSTRUCTIONS.md) | How to work across these repositories |
| 2 | [`PROJECT_CHARTER.md`](PROJECT_CHARTER.md) | What the product is and is *not* |
| 3 | [`PRODUCT_PRINCIPLES.md`](PRODUCT_PRINCIPLES.md) | How product trade-offs resolve |
| 4 | [`ENGINEERING_PRINCIPLES.md`](ENGINEERING_PRINCIPLES.md) | How code is structured |
| 5 | [`AI_MASTER_PROMPT.md`](AI_MASTER_PROMPT.md) | Contract for AI contributors |

**Then, by tier**

| Tier | Directory | Contents |
|---|---|---|
| 0 | [`00-governance/`](00-governance/) | Hierarchy, glossary, architecture decision records |
| 1 | [`01-product-discovery/`](01-product-discovery/) | Stakeholders, modules, features, **business rules**, journeys, permissions, notifications |
| 2 | [`02-system-design/`](02-system-design/) | Architecture, multi-tenancy, security, real-time tracking, notifications |
| 3 | [`03-database/`](03-database/) | Data model, ERD, table specs, RLS, migrations |
| 4 | [`04-api/`](04-api/) | API standards, error catalog, per-module endpoints |
| 5 | [`05-ui/`](05-ui/) | Design system, screen inventory, per-client specs |
| 6 | [`06-development/`](06-development/) | Coding standards, project structure, setup, definition of done |
| 7 | [`07-testing/`](07-testing/) | Test strategy, test cases, safety-critical matrix |
| 8 | [`08-deployment/`](08-deployment/) | Environments, CI/CD, observability, DR |

---

## Quick Start

Prerequisites: JDK 21, Docker, Flutter 3.x. Run from the parent directory holding all seven repositories.

```bash
# 1. Start PostgreSQL and Redis
docker compose -f guardian-infra/docker-compose.yml up -d

# 2. Build and test the backend (its tests read this repository)
cd guardian-backend && ./gradlew build

# 3. Run the API (applies Flyway migrations on startup)
./gradlew :guardian-api:bootRun

# 4. Analyse and test a Flutter client
cd ../guardian-parent-app && flutter analyze && flutter test
```

Full setup, including seed data and troubleshooting: [`06-development/LOCAL_SETUP.md`](06-development/LOCAL_SETUP.md).

---

## Core Concepts

| Term | Meaning |
|---|---|
| **Organization** | A school group — the billing and isolation boundary (the tenant) |
| **School** | A school within an organization |
| **Route** | An ordered sequence of stops served by a vehicle |
| **Trip** | One execution of a route on a date, in a direction |
| **Boarding Event** | An immutable record of a student boarding or alighting |
| **Handover** | Verified release of a student to an authorised guardian |

Full vocabulary: [`00-governance/GLOSSARY.md`](00-governance/GLOSSARY.md).

---

## Contributing

Read [`06-development/DEFINITION_OF_DONE.md`](06-development/DEFINITION_OF_DONE.md) and [`06-development/GIT_WORKFLOW.md`](06-development/GIT_WORKFLOW.md).

Every feature carries an ID from [`FEATURE_INVENTORY.md`](01-product-discovery/FEATURE_INVENTORY.md), and every business rule in [`BUSINESS_RULES.md`](01-product-discovery/BUSINESS_RULES.md) has a test that references it by ID. Changes that break that traceability fail review — `BusinessRuleTraceabilityTest` in `guardian-backend` enforces it by parsing this repository directly.

---

## Status

Foundation stage — documentation complete across all tiers; backend scaffold with the tenancy module fully implemented as the pattern reference. See [`00-governance/adr/`](00-governance/adr/) for decisions still marked *Proposed*.
