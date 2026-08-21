# AGENTS

Purpose: Provide concise, discoverable instructions for AI coding agents and human contributors about how to behave when automating tasks in this repository.

## Golden Rule — No Over-Engineering

The most common failure mode for an AI agent in this workspace is doing *too much*: reading every governance doc for a one-line fix, writing a long impact analysis for a trivial change, adding architecture, ADRs, or tests nobody asked for, or editing files outside the scope of the request. That failure mode is explicitly called out and gated in `documentation/INSTRUCTIONS.md` STEP 0 — read it before starting any task.

In short:

1. Size the task first (Trivial / Standard / Architectural — `documentation/INSTRUCTIONS.md` STEP 0). Do only what that tier calls for.
2. A typo, small bug fix, config tweak, or copy change gets a direct fix and a 1–2 line explanation — not a governance ritual.
3. Stay inside the files the request actually touches. Don't refactor, rename, or "improve" anything else, even if it looks wrong — say something instead of fixing it.
4. Don't add new abstractions, dependencies, docs, or tests unless the task needs them to be correct, or the user asked for them.
5. Don't open more files, read more docs, or run more commands/tools than the task requires.
6. If scope is unclear, ask a specific question rather than doing extra work "to be safe."

This does not relax safety, security, or tenant-isolation requirements — those apply at every tier. It only stops process ceremony from being applied to work that doesn't need it.

Contents
- Why: Quick reference so automated agents follow the project's governance and engineering standards.
- Where to look first: see `documentation/INSTRUCTIONS.md` and `documentation/FLUTTER_APP_INSTRUCTIONS.md`.
- How to use: prefer linking to existing docs rather than copying them; be minimal and actionable.

Minimal agent checklist

1. Size the task (Trivial / Standard / Architectural — `documentation/INSTRUCTIONS.md` STEP 0). For Trivial work, skip straight to step 4 below.
2. Read `documentation/INSTRUCTIONS.md` (governance) and `documentation/FLUTTER_APP_INSTRUCTIONS.md` (Flutter specifics) — Standard/Architectural tier only.
3. Identify the affected project(s) under the workspace root (e.g., `flutter/driver_attender_app`, `flutter/parent_app`) and produce a short plan before making changes (requirement summary, docs referenced, impact analysis, implementation sketch) — Standard/Architectural tier only.
4. When producing code: follow Clean Architecture, SOLID, DI, and the repo's `ENGINEERING_PRINCIPLES.md`, scaled to the tier — a one-line fix doesn't need a new layer of indirection to satisfy SOLID.
5. Link to relevant docs and add ADRs only for genuine architecture decisions, not for every change.

Prompt template (copy into prompts or use interactively)

"You are an expert developer contributing to the Guardian Platform. Read `documentation/INSTRUCTIONS.md` and `documentation/FLUTTER_APP_INSTRUCTIONS.md` before writing code. Target project: [PROJECT_NAME] at [PROJECT_PATH]. Requirement: [SHORT_REQUIREMENT]. Provide: (1) requirement summary, (2) docs referenced, (3) business rules applied, (4) proposed solution and files changed, (5) impact analysis, (6) tests and verification steps, then the minimal production-quality code changes."

Files added or updated

- `documentation/FLUTTER_APP_INSTRUCTIONS.md`: Flutter-specific guidance and a prompt template for AI agents.
- `documentation/INSTRUCTIONS.md`: updated to reference the new Flutter instructions file.

How to enforce

- Add a short line in your PR template reminding contributors to run `flutter analyze` for Flutter projects and link the ADR when architectural changes are made.
- Optionally add `.github/copilot-instructions.md` to shadow or extend these rules for GitHub Copilot-specific workflows.

If you want, I can also create `.github/copilot-instructions.md` containing a brief, machine-friendly subset of these directives.
