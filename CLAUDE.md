# Instructions for Claude — Guardian Platform workspace

This file applies to every project in this workspace: `guardian-backend`, `guardian-admin-web`, `guardian-driver-app`, `guardian-parent-app`, `guardian-infra`, `guardian-docs`.

Read `AGENTS.md` in this same directory — it's the shared entry point for every AI agent working here (Claude, Copilot, Codex) and links to the full governance docs under `guardian-docs/`, starting with `guardian-docs/INSTRUCTIONS.md`.

## The rule that matters most here: don't over-engineer

This repo's governance docs (`INSTRUCTIONS.md`, `AI_MASTER_PROMPT.md`, `ENGINEERING_PRINCIPLES.md`) describe a thorough process — Clean Architecture, ADRs, an 8-section response format, full impact analysis. That process is genuinely needed for new features and architectural changes in a safety-critical, multi-tenant system. It is not needed for every prompt, and applying it to everything is the specific problem this file exists to stop.

Default to the smallest correct change:

- **Size the task first.** `guardian-docs/INSTRUCTIONS.md` STEP 0 defines three tiers — Trivial, Standard, Architectural. State which tier a request is in one line, then do only what that tier calls for. Most day-to-day requests (bug fixes, small tweaks, copy changes, config edits) are Trivial.
- **Trivial work gets a direct fix, not a ritual.** No Clean Architecture write-up, no new ADR, no new doc, no 8-section report, no new test unless one is needed to prove the fix. Just make the change and explain it in 1–2 lines.
- **Touch only what the request is about.** Don't refactor, rename, reorganize, or "clean up" code, tests, or docs that weren't asked about, even if something else looks wrong nearby — mention it instead of fixing it.
- **Don't add things nobody asked for.** No new layers, interfaces, patterns, dependencies, files, docs, or tests unless the existing code genuinely can't solve the problem without them, or the user asked for them.
- **Don't over-consume tools.** Don't read more files, open more documents, or run more shell/tool calls than the task requires. Reading a dozen governance documents to fix one line defeats the point of having a tiering system at all.
- **When scope is ambiguous, ask.** A specific clarifying question beats doing extra work "to be safe."

## What this file does not change

Safety, security, and tenant-isolation requirements (`ENGINEERING_PRINCIPLES.md` §9–§11: multi-tenancy, security by design, auditability) apply at every tier, always. This file only stops process ceremony — read-everything, write-everything, scaffold-everything — from being applied to work that doesn't need it. For genuinely Standard or Architectural changes, follow the full process in `guardian-docs/INSTRUCTIONS.md` as written.
