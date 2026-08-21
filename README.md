# Guardian Platform

Enterprise, multi-tenant SaaS platform for school transportation and child safety. The product Guardian builds is not "where is the bus" — it is *knowing a child is safe throughout the journey between home and school*, with every stage of that journey timestamped, attributable, auditable, and notification-capable.

## Start here

- [`CLAUDE.md`](CLAUDE.md) — the repository-root control document for AI agents and human contributors: project context, product vision, engineering/security/multi-tenant rules, naming conventions, folder structure, and the quality gate every change is checked against.
- [`AGENTS.md`](AGENTS.md) — the shared entry point for every AI tool working in this workspace (Claude, Copilot, Codex), and the single most important rule: size the task before doing it.
- [`documentation/`](documentation/) — the full governance, product, architecture, database, API, UI, development, testing, and deployment documentation, in tiers 0–8. `documentation/INSTRUCTIONS.md` is the contribution protocol; `documentation/00-governance/DOCUMENT_HIERARCHY.md` is the authority order when documents disagree.
- [`AI_CONTENT/`](AI_CONTENT/) — how AI agents work in this repository: the standard agent workflow, notes convention, reusable process workflows, and the specialised research agent.

## Repository layout

Each project below is its own independent git repository, cloned side by side in this workspace directory because several of them resolve each other by relative path (see `documentation/06-development/PROJECT_STRUCTURE.md`).

| Path | What it is |
|---|---|
| `backend/` | Gradle multi-module Java/Spring backend — Clean Architecture, PostgreSQL with row-level security |
| `flutter/parent_app/` | Flutter — parent/guardian app |
| `flutter/driver_attender_app/` | Flutter — driver & attendant app, offline-first |
| `flutter/teacher_app/` | Placeholder — not yet implemented |
| `flutter/shared_packages/guardian_theme/` | Shared Dart package — design tokens and theme |
| `admin/` | Flutter Web — school/transport admin console |
| `infrastructure/` | docker-compose and local database bootstrap |
| `documentation/` | Product, architecture, and process documentation (tiers 0–8) |
| `api/`, `deployment/`, `operations/`, `scripts/` | Placeholders reserved for API contracts, deployment configs, operational runbooks, and repo-wide scripts as the platform grows |

## Getting set up locally

See [`documentation/06-development/LOCAL_SETUP.md`](documentation/06-development/LOCAL_SETUP.md) for environment setup, and `.vscode/launch.json` / `.vscode/tasks.json` at this root for preconfigured dev/prod run and terminal tasks for each project.

## Working on this repository with AI assistance

Read `CLAUDE.md` and `AGENTS.md` before making a change of any real size. The short version of both: size the request (Trivial / Standard / Architectural) before deciding how much process it needs, and never guess at a requirement that isn't written down — ask.
