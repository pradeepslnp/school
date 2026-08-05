# AGENTS

Purpose: Provide concise, discoverable instructions for AI coding agents and human contributors about how to behave when automating tasks in this repository.

Contents
- Why: Quick reference so automated agents follow the project's governance and engineering standards.
- Where to look first: see `guardian-docs/INSTRUCTIONS.md` and `guardian-docs/FLUTTER_APP_INSTRUCTIONS.md`.
- How to use: prefer linking to existing docs rather than copying them; be minimal and actionable.

Minimal agent checklist

1. Read `guardian-docs/INSTRUCTIONS.md` (governance) and `guardian-docs/FLUTTER_APP_INSTRUCTIONS.md` (Flutter specifics).
2. Identify the affected project(s) under the workspace root (e.g., `guardian-driver-app`, `guardian-parent-app`).
3. Produce a short plan before making changes (requirement summary, docs referenced, impact analysis, implementation sketch).
4. When producing code: follow Clean Architecture, SOLID, DI, and the repo's `ENGINEERING_PRINCIPLES.md`.
5. Link to relevant docs and add ADRs for architecture decisions.

Prompt template (copy into prompts or use interactively)

"You are an expert developer contributing to the Guardian Platform. Read `guardian-docs/INSTRUCTIONS.md` and `guardian-docs/FLUTTER_APP_INSTRUCTIONS.md` before writing code. Target project: [PROJECT_NAME] at [PROJECT_PATH]. Requirement: [SHORT_REQUIREMENT]. Provide: (1) requirement summary, (2) docs referenced, (3) business rules applied, (4) proposed solution and files changed, (5) impact analysis, (6) tests and verification steps, then the minimal production-quality code changes."

Files added or updated

- `guardian-docs/FLUTTER_APP_INSTRUCTIONS.md`: Flutter-specific guidance and a prompt template for AI agents.
- `guardian-docs/INSTRUCTIONS.md`: updated to reference the new Flutter instructions file.

How to enforce

- Add a short line in your PR template reminding contributors to run `flutter analyze` for Flutter projects and link the ADR when architectural changes are made.
- Optionally add `.github/copilot-instructions.md` to shadow or extend these rules for GitHub Copilot-specific workflows.

If you want, I can also create `.github/copilot-instructions.md` containing a brief, machine-friendly subset of these directives.
