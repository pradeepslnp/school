# Guardian Platform

**Repository root control document.** Every AI agent and human contributor working anywhere in this repository reads this file first.

This file is deliberately an *entry gate*, not the deepest source of truth. The full, actively-maintained governance, product, architecture, and process documentation lives in [`documentation/`](documentation/) (tiers 0–8) and its authority order is defined there in [`documentation/00-governance/DOCUMENT_HIERARCHY.md`](documentation/00-governance/DOCUMENT_HIERARCHY.md) — that document, not this one, is what wins when two documents disagree. This file's job is to orient any agent quickly, state the rules that apply everywhere regardless of which module they're touching, and point to where the real depth lives. See also [`AGENTS.md`](AGENTS.md), which is the shared entry point for every AI tool (Claude, Copilot, Codex) working in this workspace and states the single most important operating rule up front.

---

## 1. Project Context

**Guardian Platform** is an enterprise, multi-tenant SaaS platform for school transportation and child safety. It is a monorepo-style workspace of independently-versioned projects cloned side by side:

```
school/                            repository root (this file lives here)
├── CLAUDE.md                      you are here
├── AGENTS.md                      cross-tool entry point; read this too
├── AI_CONTENT/                    agent workflows, notes, research agent, prompts
├── documentation/                 tiers 0–8: charter, principles, architecture, API, UI, dev, test, deploy
├── backend/                       Gradle multi-module Java/Spring backend
├── flutter/
│   ├── parent_app/                Flutter — parent/guardian app
│   ├── driver_attender_app/       Flutter — driver & attendant app, offline-first (ADR-0008)
│   ├── teacher_app/                placeholder — not yet implemented
│   └── shared_packages/
│       └── guardian_theme/        shared pure Dart — design tokens, theme
├── admin/                         Flutter Web — school/transport admin console
├── infrastructure/                docker-compose, local DB bootstrap
├── api/                           API contracts / OpenAPI specs (placeholder)
├── deployment/                    deployment scripts, environment configs (placeholder)
├── operations/                    runbooks, on-call material (placeholder)
└── scripts/                       repo-wide dev/maintenance scripts (placeholder)
```

Each project folder (`backend/`, `flutter/parent_app/`, `flutter/driver_attender_app/`, `admin/`, `flutter/shared_packages/guardian_theme/`, `documentation/`) is its own independent git repository with its own remote. This root repository (`school`) tracks the shared root-level files (`CLAUDE.md`, `AGENTS.md`, `.vscode/`, `.github/workflows/`, `documentation/`) and does **not** track the contents of the other project folders — they are siblings living in the same workspace directory because several of them resolve each other by relative path (see §9, §15, and [`documentation/06-development/PROJECT_STRUCTURE.md`](documentation/06-development/PROJECT_STRUCTURE.md)). Do not assume a single `git commit` at the root captures changes made inside `backend/`, `flutter/*`, or `admin/` — each has to be committed in its own repository.

**2026-08 restructure note:** this workspace was reorganised from a flat set of `guardian-backend`, `guardian-parent-app`, `guardian-driver-app`, `guardian-admin-web`, `guardian-infra`, `guardian-theme`, `guardian-docs` sibling folders into the nested layout above. If you find a path anywhere in this repo — code, docs, CI, editor config — still pointing at an old `guardian-*` folder name, that is a documentation/config defect left over from the move. Fix it if it's in scope of what you're doing, or flag it if it isn't; do not silently work around it.

## 2. Product Vision

Guardian is **not** a bus-tracking app. The product being built is: *knowing that a child is safe throughout the journey between home and school*, and giving parents verified confidence about that journey rather than a dot on a map.

A child's journey — not the vehicle — is the primary object the system models:

```
Home → Guardian Handover → Vehicle Boarding → Transportation → School Arrival
     → Teacher/Attender Confirmation → Classroom → School Departure
     → Vehicle Boarding → Transportation → Home Arrival → Guardian Handover
```

Every stage above is timestamped, attributable to an actor, auditable, GPS-aware where applicable, and capable of triggering a notification. The differentiator over conventional tracking products is captured in one line: traditional apps answer *"where is the bus?"*; Guardian answers *"where is my child, and who is responsible for them right now?"*

Full mission, scope, non-goals, stakeholders, and success measures: [`documentation/PROJECT_CHARTER.md`](documentation/PROJECT_CHARTER.md). Trade-off resolution when product principles conflict (child safety always wins): [`documentation/PRODUCT_PRINCIPLES.md`](documentation/PRODUCT_PRINCIPLES.md).

## 3. About the Developer

Documented only from what this project has established — nothing here is invented:

- Building Guardian as a serious commercial, multi-tenant SaaS platform, not a prototype.
- Wants AI-assisted development used extensively, but wants production-quality output: strong architecture, clear documentation, step-by-step implementation, enterprise-level engineering practice, reusable and maintainable code.
- Prefers to understand the reasoning behind a recommendation before implementation happens.
- When a requirement is unclear, the developer wants a question, not an invented assumption — this is stated as a hard rule in multiple places in this repository (§17, §21, and [`documentation/AI_MASTER_PROMPT.md`](documentation/AI_MASTER_PROMPT.md)), not a courtesy.
- Has already made real architectural decisions that this file must not contradict: Clean Architecture on the backend enforced by ArchUnit, PostgreSQL row-level security as the tenant-isolation mechanism (not just application-level filtering), BLoC-based feature-first Flutter apps, and a deliberate anti-over-engineering discipline (§4, §20) layered on top of that heavier process.

## 4. Communication Style

Direct, technical, structured, practical, and teaching-oriented — explain the "why," not just the "what," but do not pad an explanation that doesn't need one.

**Before recommending an architectural approach:**

1. Explain the problem.
2. Explain the recommendation.
3. Explain relevant alternatives.
4. Explain why the recommendation fits *this* platform specifically (not architecture in the abstract).
5. Then proceed.

**Do not blindly agree.** If a proposed approach introduces a security problem, a scalability problem, a data-integrity problem, an architectural problem, a maintenance problem, or a child-safety risk, say so plainly and propose the better alternative before implementing anything.

**Size the task before doing it.** This repository has a real, working heavy process (Clean Architecture, ADRs, an 8-section response format, full impact analysis) that exists for genuine architectural change — and a real, deliberate rule that most requests are *not* that. [`documentation/INSTRUCTIONS.md`](documentation/INSTRUCTIONS.md) STEP 0 defines three tiers: **Trivial, Standard, Architectural.** State which tier a request falls into, in one line, before doing anything else:

- **Trivial** (typo, one-file bug fix, copy/config change): make the fix, explain it in 1–2 lines. No ADR, no 8-section report, no new doc, no test unless one is needed to prove the fix.
- **Standard / Architectural**: follow the full process in `documentation/INSTRUCTIONS.md` and the output structure in `documentation/AI_MASTER_PROMPT.md`.

Applying the heavy process to a Trivial request is exactly the failure mode this rule exists to prevent — see `AGENTS.md` and `documentation/INSTRUCTIONS.md` STEP 0 for the fuller statement of why this matters here specifically.

## 5. Product Rules

These are load-bearing product decisions already made. Do not silently relitigate them; if one seems wrong for a specific case, say so and propose an amendment rather than deviating quietly.

- **Journey, not vehicle, is the core object** (§2). Every module should be explainable in terms of what it does for the child's journey record.
- **Student / guardian model:** a student has a unique admission number within a school; belongs to one active class per academic year with retained class history; a parent may have multiple children; a child may have multiple guardians; a guardian may be authorised for multiple children; siblings may travel together.
- **Absence:** a parent or authorised user can mark a student absent before a trip. The bus must not wait unnecessarily at that pickup point; relevant transport personnel are informed; the parent receives confirmation.
- **Bus / driver / attender transfers** are controlled and fully audited: original bus, replacement bus, original driver, replacement driver, time, location, reason, initiated-by, approved-by, and the affected student list are all recorded for every transfer. See the transfer workflow in §8 of the original platform specification and formalise new instances of it as ADRs plus entries in `documentation/01-product-discovery/BUSINESS_RULES.md`.
- **Route changes** are controlled and communicated, not silent.
- **Wrong-bus and missed-bus detection** are first-class safety features, not edge cases: a student boarding an unexpected bus, or not boarding within the expected window, must generate an alert to the relevant parties (parent always; attendant/driver; school staff where tenant-configured).
- **Parent drop-off/handover is separate from official school attendance.** A parent-initiated handover (geofence-detected arrival, photo capture, teacher/attender confirmation) is a transport/handover event. It is never the authority for official academic attendance — that remains with authorised school personnel. Do not let a feature blur this line; it is a compliance and safety boundary, not a UX inconvenience.
- **Notifications** are event-driven, templated per tenant, and cover at minimum: bus started, approaching/reaching stop, child boarded, child did not board, child reached school, child left school, boarded for return trip, reached home, driver changed, attendant changed, delay, breakdown, transfer, emergency, unauthorised pickup. Configurability (channel, language, template, threshold) is per tenant — see `documentation/01-product-discovery/NOTIFICATION_CATALOG.md`.
- **MVP discipline:** every feature is classified MVP / Phase 2 / Phase 3 / Future / Research in `documentation/01-product-discovery/FEATURE_INVENTORY.md`. Being technically interesting does not make something MVP. Face recognition, RFID, smart watches, CCTV integration, and AI route optimisation are explicitly future/research — do not build them into the current milestone unless asked.

## 6. Engineering Rules

The authoritative version of this section is [`documentation/ENGINEERING_PRINCIPLES.md`](documentation/ENGINEERING_PRINCIPLES.md); this is the summary every agent should hold in working memory:

- **Clean Architecture, dependency direction inward:** `interfaces → application → domain`, with `infrastructure` implementing application-layer ports. Domain code never imports framework types.
- **Feature-first, not layer-first** package organisation (`com.guardian.<module>/domain|application|infrastructure|interfaces`, not `com.guardian.controllers`).
- **SOLID**, applied concretely: one use case does one operation; new notification channels or GPS device types are new implementations, never a growing switch statement.
- **Repository pattern:** repositories are domain-facing interfaces in `application`, implemented in `infrastructure`. A JPA entity never leaves `infrastructure`; a domain object is never serialised directly to a client. This costs more code than one annotated class per entity — it is worth it because safety records outlive the current ORM choice.
- **Constructor injection only.** No field injection, no static mutable state, no service locators.
- **DRY with judgement:** a business rule has exactly one implementation. If a rule is enforced in the UI, that is for UX only — the server enforces it authoritatively, always.
- **KISS:** the simplest design that satisfies the requirement and its stated scale target. Naming the second concrete implementation an abstraction enables is the bar for adding it; if none exists, don't add it.
- **No business logic in UI**, ever, in either the Flutter apps or the admin web client.
- **No placeholder code.** No `TODO` without a linked issue, no commented-out blocks, no stub thrown exceptions left behind, no pseudo-production shortcuts. If something can't be finished properly, it is documented as not done — not merged half-done.

## 7. Security Rules

- Authorisation is decided server-side, inside tenant scope, on every request. Deny by default — a new endpoint with no explicit permission fails closed.
- Never trust a client-supplied identifier. Validate at the boundary.
- Secrets come from environment/secret manager, never from source.
- Child PII is minimised, encrypted at rest and in transit, and access is audited.
- Rate limiting, session management, and secure storage apply to every new API surface and every new mobile feature that touches auth or location.
- Never expose more child or parent information than the requesting user's role and tenant scope entitle them to.

## 8. Multi-Tenant Rules

Multi-tenancy is structural, not a filter bolted on top:

- Every tenant-scoped table carries `tenant_id`. **PostgreSQL Row-Level Security is the enforcement boundary** — application-level filtering is a convenience on top of it, never the control itself.
- Tenant context is established once per request and propagated through it; it is never a parameter a developer could forget to pass.
- A repository method that can return cross-tenant rows must be explicitly named as such and permission-gated — it is never the default.
- Never hardcode a school ID, school name, logo, color, language, notification message, feature flag, or any other tenant-specific value. All of it is configuration: theme (logo, name, primary/secondary color, typography), language (UI and notification), date/time format, timezone, geofence radius, attendance rules, emergency policy, and feature availability per school.
- Design for multiple campuses, multiple transport vendors, multiple depots, and thousands of schools — this is a scale assumption, not a someday concern.

Detail: [`documentation/02-system-design/MULTI_TENANCY.md`](documentation/02-system-design/MULTI_TENANCY.md), [`documentation/03-database/RLS_POLICIES.md`](documentation/03-database/RLS_POLICIES.md).

## 9. Architecture Rules

- System design detail lives in `documentation/02-system-design/` — architecture overview, multi-tenancy, security architecture, real-time tracking design, notification architecture, audit & logging, integration architecture, and scalability are each their own document. Read the relevant one before proposing a change to that area.
- **Degradation is designed, not incidental.** A driver app losing connectivity must not lose safety data — events queue and sync (see ADR-0008, offline-first driver app).
- Cross-project dependencies are deliberately kept to exactly three (see `documentation/06-development/PROJECT_STRUCTURE.md` §Cross-repository dependencies). Adding a fourth requires an ADR — the split between independent repositories is only worth its cost while the couplings stay countable.
- Extensibility for future transport modes (vans, daycare, corporate/college transport) and future hardware (GPS variants, RFID, smart watches, CCTV, AI route optimisation) should inform interface design (e.g., device adapters behind a common ingestion port) without pulling any of that work into the current milestone.

## 10. Flutter Rules

- State management is **BLoC**, feature-first, with five parts per feature: `bloc/`, `ui/`, `widgets/`, `repository/`, `data_provider/`. Dependency direction is one-way: `ui/widgets → bloc → repository → data_provider`. A feature without remote data has no `data_provider/`; a feature with no decisions yet has no `bloc/` — do not create empty folders just to satisfy the pattern.
- Every app has exactly one `RestClient` and one `ApiResponse` type in `core/network/`. Every network call goes through it. `RestClient` never throws for a transport fault — sockets errors, timeouts, and unparseable replies all become `ApiResponse.transportFailure`, so a repository handles "no network" the same way it handles "server said no."
- **Retry policy is a safety rule, not a convenience:** `GET`/`PUT`/`DELETE` retry; `PATCH` does not; `POST` retries only with an idempotency key. A retried `POST` without one can record a boarding or handover event twice.
- Shared design tokens and theme come from `flutter/shared_packages/guardian_theme`. Its domain layers must not import `package:flutter/material.dart` where a portability boundary exists.
- Reference implementation for new features: the `login` feature in the parent app. Copy its shape; do not invent a new one.
- Run `flutter analyze` clean before considering Flutter work done. Do not add new widget tests unless asked.

Full detail: [`documentation/FLUTTER_APP_INSTRUCTIONS.md`](documentation/FLUTTER_APP_INSTRUCTIONS.md), [`documentation/06-development/CODING_STANDARDS_FLUTTER.md`](documentation/06-development/CODING_STANDARDS_FLUTTER.md).

## 11. Backend Rules

**The backend is Java + Spring, built with Gradle as a multi-module project (`backend/settings.gradle.kts`), not NestJS/TypeScript.** Any instruction, template, or prior conversation that assumes a Node/NestJS backend for this repository is wrong for this codebase — flag it rather than acting on it.

- Modules: `guardian-common` (cross-cutting only, no business rules), `guardian-tenancy` (the reference implementation — copy its structure for new modules), `guardian-identity`, `guardian-api` (bootstrap, security, migrations). Package by feature, then by layer: `com.guardian.<module>/domain|application|infrastructure|interfaces`.
- One class, one operation for use cases (`CreateSchoolUseCase`, not a service class with ten methods). Constructor injection only.
- Every safety-relevant state change writes an append-only audit record (actor, action, subject, timestamp, source, reason where applicable) **in the same transaction** as the change it audits.
- Domain failures are typed domain exceptions. One global exception handler maps them to the documented error envelope (`documentation/04-api/ERROR_CATALOG.md`). Never swallow-and-rethrow at multiple layers.
- Structured JSON logs, correlation ID and tenant ID on every entry, **no child PII in logs**.
- Enforcement is automated, not aspirational: an ArchUnit test suite in `guardian-common` fails the build on a layering violation. CI (`.github/workflows/ci.yml`) runs `cd backend && ./gradlew build -x test`.

Full detail: [`documentation/06-development/PROJECT_STRUCTURE.md`](documentation/06-development/PROJECT_STRUCTURE.md) (Backend Module Layout), [`documentation/06-development/CODING_STANDARDS_BACKEND.md`](documentation/06-development/CODING_STANDARDS_BACKEND.md), [`documentation/06-development/ARCHITECTURE_ENFORCEMENT.md`](documentation/06-development/ARCHITECTURE_ENFORCEMENT.md).

**Real-time, auth, notifications, maps, storage, infra** (as already adopted, confirmed against the actual codebase rather than assumed): PostgreSQL as the database with row-level security for tenant isolation, Flyway migrations. Redis for caching. WebSocket for real-time position/status updates. JWT with refresh tokens for authentication. Firebase Cloud Messaging for push notifications. Google Maps for mapping. AWS S3 or S3-compatible storage for documents/photos. Docker for containerisation; GitHub Actions for CI/CD. Keep infrastructure providers replaceable behind ports — do not let a provider SDK leak into the domain layer.

## 12. Database Rules

- PostgreSQL. Row-Level Security is the tenant-isolation control, applied in the same migration that creates a tenant-scoped table — never added later as an afterthought.
- Migrations via Flyway. See `documentation/03-database/MIGRATION_STRATEGY.md`, `documentation/03-database/CONVENTIONS.md`, `documentation/03-database/INDEXING_AND_PARTITIONING.md`.
- Safety-relevant tables (boarding, handover, incidents, audit) are append-only.
- New tables get a row in `documentation/03-database/tables/` alongside the migration, and the module adding them updates `MODULE_MAP.md` and confirms no dependency cycle.

## 13. Naming Conventions

| Context | Convention | Example |
|---|---|---|
| Backend class/file (Java) | PascalCase, one class per file | `SchoolController.java`, `CreateSchoolUseCase.java`, `SchoolRepositoryAdapter.java` |
| Backend use case | `<Verb><Noun>UseCase` | `CreateSchoolUseCase` |
| Backend port | `<Noun>Repository`, `<Noun>Gateway` | `SchoolRepository` |
| Backend adapter | `<Noun>RepositoryAdapter` | `SchoolRepositoryAdapter` |
| Backend DTO | `<Verb><Noun>Request` / `<Noun>Response` | `CreateSchoolRequest`, `SchoolResponse` |
| Backend JPA entity | `<Noun>Entity` | `SchoolEntity` |
| Backend domain exception | `<Problem>Exception` | — |
| Backend unit / integration test | `<Class>Test` / `<Class>IT` | `SchoolTest`, `SchoolRepositoryAdapterIT` |
| Dart/Flutter file | `snake_case.dart` | `student_check_in_bloc.dart`, `student_repository.dart` |
| Markdown documentation | `UPPER_SNAKE_CASE.md`, matching the established `documentation/` convention | `PROJECT_CHARTER.md` |

Never invent an abbreviation that isn't already established project terminology. Never mix naming conventions within the same layer.

## 14. File Naming Rules

See §13 for the pattern table. The specific rule to hold onto: **never** `LoginMainScreen.dart`, `loginMainScreen.dart`, or `Login_Main_Screen.dart` for Dart files — only `login_main_screen.dart`. Never a `student.controller.ts`-style TypeScript-kebab convention for backend files — the backend is Java, and Java files are PascalCase, one public type per file.

## 15. Folder Structure

The top-level layout is in §1. Within `backend/`, follow the module layout in `documentation/06-development/PROJECT_STRUCTURE.md` exactly (`domain/`, `application/{usecase,port,command}/`, `infrastructure/persistence/`, `interfaces/rest/{dto}/`) — copy `guardian-tenancy`'s shape for a new module rather than inventing one. Within a Flutter app, follow the five-part feature shape in §10.

Structural changes to this repository (adding a new project folder, moving something, changing the top-level layout) must be documented — in this file and in `documentation/06-development/PROJECT_STRUCTURE.md` — before being implemented, not discovered afterward by whoever opens the repo next.

## 16. Documentation Rules

- `documentation/` is the source of truth for product, architecture, API, UI, process, testing, and deployment decisions, organised in tiers 0–8. Its authority order over itself and this file is defined in `documentation/00-governance/DOCUMENT_HIERARCHY.md` — read that before assuming which of two documents wins a disagreement.
- A feature ID (`TRK-003`) and a business rule ID (`BR-BOARD-004`) are the connective tissue of this repository. Adding a feature means adding its ID to `documentation/01-product-discovery/FEATURE_INVENTORY.md` and referencing it from the relevant API doc, UI doc, and test. A feature that exists in code but not in the inventory is untracked work.
- Documentation is not optional overhead on Standard/Architectural work — it is part of the definition of done (§20).
- `AI_CONTENT/` (this directory's sibling, described in full in §17–§19) is a different kind of documentation: it governs how AI agents work, not what the product does. Do not put product requirements there, and do not put agent-process rules inside `documentation/`.

## 17. Agent Behavior

An agent working in this repository behaves like a specialised member of an engineering organisation, not a generic chatbot. Concretely:

- Read this file and `AGENTS.md` first. Size the task (§4) before doing anything else.
- Respect existing architecture and business rules; do not invent either.
- Identify conflicts between what's being asked and what's documented, and surface them — do not resolve a conflict by quietly editing the lower-tier document to agree, and do not resolve it by guessing.
- Keep changes scoped to what was asked. Do not refactor, rename, or "clean up" anything else, even if it looks wrong nearby — mention it instead.
- Consider security, multi-tenancy, auditability, and child safety on every change that touches them, regardless of how small the request seems.
- Consider testing and documentation impact as part of the change, not as a follow-up someone else does later.

The full standard process every agent follows is [`AI_CONTENT/AGENT_WORKFLOW.md`](AI_CONTENT/AGENT_WORKFLOW.md). The output format for a Standard/Architectural response is defined there and in `documentation/AI_MASTER_PROMPT.md`.

## 18. Research Rules

Research tasks (competitor, technology, architecture, product, industry, regulatory, pricing, market, best-practice) are handled by the pattern in [`AI_CONTENT/agents/research_agent/CLAUDE.md`](AI_CONTENT/agents/research_agent/CLAUDE.md) and [`AI_CONTENT/agents/research_agent/research_agent.md`](AI_CONTENT/agents/research_agent/research_agent.md). The short version: prefer primary and official sources, use current sources for anything time-sensitive, separate fact from opinion, record source URLs and dates, and never let research findings silently become product requirements — a research report recommends; only an ADR or an update to `documentation/` decides.

## 19. Development Workflow

1. Size the task (Trivial / Standard / Architectural).
2. For Standard/Architectural: identify relevant `documentation/` tiers, affected modules, applicable business rules, and dependencies; check for conflicts; state the proposed approach before writing code.
3. Implement only after requirements are clear enough that nothing safety-relevant is being guessed.
4. Validate: run or recommend the appropriate tests (`flutter analyze` for Flutter, the module's test suite plus ArchUnit for backend).
5. Update `documentation/` and `AI_CONTENT/agents/notes/` as required (§16, §19 of `AI_CONTENT/AGENT_WORKFLOW.md`).
6. Produce output in the structured format for Standard/Architectural work; skip the ceremony for Trivial work.

## 20. Quality Gate

Before considering any Standard or Architectural work complete, verify: requirements and business rules satisfied; multi-tenancy preserved (RLS intact, nothing hardcoded per-tenant); security considered (authZ, validation, no PII leakage); error handling implemented with typed exceptions; auditability considered for any safety-relevant change; tests created and passing, including a tenant-isolation test where a new module is involved; documentation updated; naming conventions followed (§13); no unnecessary code; no unrelated changes bundled in.

## 21. Forbidden Behaviors

Never: invent a requirement, API, or database field; hardcode any tenant-specific value (§8); ignore `documentation/` in favour of memory of a previous conversation; bypass authorisation; put business logic in UI; duplicate business logic between client and server; delete existing functionality without approval; introduce a dependency without justification; perform unrelated refactoring; claim something was tested when it wasn't; claim research was performed when it wasn't; present an assumption as a fact; assume the backend is NestJS/TypeScript (it is Java/Spring/Gradle — see §11); silently redesign an existing module (extension is the default; redesign needs an ADR).

---

**Final operating principle:** the goal is not to generate code quickly. It is to build a secure, scalable, maintainable, production-quality platform that genuinely improves child safety and gives parents peace of mind. Every agent, workflow, research task, code change, document, and architectural decision in this repository should be judged against that.
