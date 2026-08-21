# Agent Workflow

**Applies to:** every AI agent working anywhere in the Guardian Platform repository.

## Goal

Ensure every AI agent works from the same project context, business rules, architecture, documentation, and quality standards — regardless of which tool is running it, which module it's touching, or which conversation started it.

## Before anything else: size the task

[`documentation/INSTRUCTIONS.md`](../documentation/INSTRUCTIONS.md) STEP 0 sizes every request into **Trivial**, **Standard**, or **Architectural** before any of the process below applies. State the tier in one line. A Trivial request (typo, one-file bug fix, copy/config change) skips straight to making the fix and a 1–2 line explanation — the standard process and output format below are for **Standard and Architectural** work. Applying the full process to Trivial work is the specific failure mode this repository's root `CLAUDE.md` and `AGENTS.md` exist to prevent.

## Standard Process (Standard / Architectural tier)

1. **Load project instructions** — root `CLAUDE.md`, `AGENTS.md`, and `documentation/INSTRUCTIONS.md`.
2. **Understand the task** — restate it, including anything inferred, before proceeding.
3. **Identify relevant documentation** — which tier(s) of `documentation/` govern this area (product discovery, system design, database, API, UI, development, testing, deployment).
4. **Identify affected modules** — which backend module(s), which Flutter app(s), which shared package(s).
5. **Identify applicable business rules** — by ID, from `documentation/01-product-discovery/BUSINESS_RULES.md`.
6. **Identify dependencies** — cross-module, cross-project (there are exactly three cross-repository dependencies in this workspace; see `documentation/06-development/PROJECT_STRUCTURE.md`), and any migration or API-compatibility dependency.
7. **Check for conflicts** — between the request and existing architecture, business rules, or a higher-tier document. Never resolve a conflict by quietly editing the lower-tier document to agree with the wrong thing; escalate it (state it plainly, propose an ADR or documentation amendment if the higher document is genuinely wrong).
8. **Explain the proposed approach** before writing code — problem, recommendation, alternatives considered, why this fits Guardian specifically.
9. **Implement only after requirements are clear.** A plausible guess in a safety-relevant system is a defect, not a shortcut. If something safety-relevant is ambiguous, ask rather than proceed.
10. **Validate the implementation** — against the business rules and requirements identified in steps 3–5.
11. **Run or recommend tests** — unit for domain rules, integration for repository/database (including RLS enforcement where tenancy is touched), contract for API shape, end-to-end for critical safety journeys. `flutter analyze` clean for any Flutter change.
12. **Update documentation if required** — the tier(s) identified in step 3, plus `FEATURE_INVENTORY.md` and `MODULE_MAP.md` if a feature or module was added or changed, plus an ADR if an architectural decision was made.
13. **Produce structured output** — the format below.
14. **Record important decisions** — in `AI_CONTENT/agents/notes/` per [`notes_workflow.md`](agents/notes/notes_workflow.md) if the decision doesn't yet belong in official documentation, or directly in `documentation/` if it does.

## Agent Output Format (Standard / Architectural tier)

```
## Task
What was requested.

## Context Reviewed
Documents and rules considered (actual paths read, not assumed).

## Requirements
Relevant requirements, including what was inferred.

## Business Rules
Rules applied, by ID where they exist.

## Approach
Proposed implementation approach and why it fits this platform.

## Changes
Files/modules affected.

## Implementation
Actual implementation. No placeholders, no pseudo-production shortcuts.

## Validation
Tests/checks performed or recommended.

## Documentation Updates
Documentation that should be updated, and by whom if not done here.

## Risks / Concerns
Anything requiring attention — including anything left uncertain.

## Next Steps
Recommended next action.
```

If the user explicitly asks for only code, omit the surrounding sections and provide the code — do not manufacture ceremony the user didn't ask for. For Trivial-tier work, skip this format entirely; a 1–2 line explanation is correct and complete.

## Reusable workflows

Task-specific workflows (feature development, backend changes, Flutter changes, database changes, API changes, testing, code review, documentation) live in [`agents/workflows/`](agents/workflows/) and are added as they're needed — see that folder's README for the convention and the list of workflows that exist versus are anticipated.

## Related

- [`agents/notes/notes_workflow.md`](agents/notes/notes_workflow.md) — how agents record decisions, open questions, and findings that aren't yet official documentation.
- [`agents/outputs/`](agents/outputs/) — where retained agent-generated artifacts live.
- [`agents/research_agent/`](agents/research_agent/) — the specialised research agent's operating rules and output format.
- [`prompts/`](prompts/) — reusable prompt templates.
