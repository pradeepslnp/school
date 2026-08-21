# INSTRUCTIONS

**Document tier:** 0 — Governance
**Status:** Active
**Authority:** This is the highest-priority document in the repository. Where any other document conflicts with this one, this document wins.

---

## Purpose

This repository contains the official documentation and source code for the **Guardian Platform**, a multi-tenant student safety and transport system for schools.

This document defines the process every contributor — human or AI — follows before answering a question, writing code, or changing documentation.

---

## STEP 0 — Size the Task First

Before doing anything else, classify the request into one of three tiers. This determines how much of the process below actually applies — most requests are **not** Architectural tier, and should not be treated like one.

| Tier | Examples | What applies |
|---|---|---|
| **Trivial** | Typo, copy/text change, log message, config value, a bug fix confined to one file or function, formatting, dependency bump | Make the change. Read only the file(s) you're touching, not the Step 1 priority list. Skip Steps 2–5 and the Response Format below — give a 1–2 line explanation of what changed and why. No new ADR, no new docs, no new tests unless one is directly required to prove the fix. |
| **Standard** | New endpoint, new UI screen, schema change, new business rule, anything touching more than one module | Full process: Steps 1–6 and the Response Format below apply. |
| **Architectural** | New service, new pattern, cross-cutting change, anything that changes how modules talk to each other | Full process + an ADR under `00-governance/adr/`. |

Rules for using this table:

- State which tier you picked in one line before proceeding (e.g. "Trivial — one-line null check in `TripService`").
- If genuinely unsure between two tiers, pick the lower one and say so — do not default to Architectural "to be safe." Escalating the process is easy if the user asks for more; doing eight sections of write-up for a typo cannot be undone.
- Safety-critical rules (child safety, tenant isolation, auth, audit trail — `ENGINEERING_PRINCIPLES.md` §9–§11) are never skipped regardless of tier. Tiering controls how much you *write about* and *scaffold around* a change, not whether the change itself is safe and correct.

**Scope discipline, every tier:**

- Touch only the files the request requires. Do not refactor, rename, reformat, reorganize, or "clean up" code, tests, or docs that weren't asked about — even if you notice something else that looks wrong. Mention it to the user instead of fixing it unprompted.
- Do not introduce a new abstraction, interface, layer, design pattern, or dependency unless the current code cannot express the fix without it. Per KISS (`ENGINEERING_PRINCIPLES.md` §7): if you can't name the concrete second case a new layer of indirection enables, don't add the layer.
- Do not open files, read documents, or run commands beyond what's needed to understand and verify this specific change. The Step 1 priority list is for Standard/Architectural work — reading twelve documents to fix one line is itself the failure mode this section exists to stop.
- Do not create documentation, ADRs, or tests that weren't requested and aren't required by this tiering, the Documentation Rule, or the Current Exception below.
- When scope is ambiguous, ask a specific question rather than doing extra work "to be safe."

---

## STEP 1 — Read Project Context (Standard / Architectural tier)

Always identify the relevant project documents before answering.

Priority order:

1. `INSTRUCTIONS.md` (this document)
2. `AI_MASTER_PROMPT.md`
3. `PROJECT_CHARTER.md`
4. `ENGINEERING_PRINCIPLES.md`
5. `PRODUCT_PRINCIPLES.md`
6. Relevant Product Discovery documents — [`documentation/01-product-discovery/`](01-product-discovery/)
7. Relevant System Design documents — [`documentation/02-system-design/`](02-system-design/)
8. Relevant API documents — [`documentation/04-api/`](04-api/)
9. Relevant Database documents — [`documentation/03-database/`](03-database/)
10. Relevant UI documents — [`documentation/05-ui/`](05-ui/)
11. Relevant Development documents — [`documentation/06-development/`](06-development/)
12. Flutter App instructions — [`documentation/FLUTTER_APP_INSTRUCTIONS.md`](FLUTTER_APP_INSTRUCTIONS.md)

Never ignore existing documentation.

---

## STEP 2 — Verify Requirement

Before writing code or documentation, understand the request and determine:

- Which module is affected — see [`MODULE_MAP.md`](01-product-discovery/MODULE_MAP.md)
- Which stakeholders are affected — see [`STAKEHOLDERS.md`](01-product-discovery/STAKEHOLDERS.md)
- Which business rules apply — see [`BUSINESS_RULES.md`](01-product-discovery/BUSINESS_RULES.md)
- Which APIs are affected
- Which database tables are affected
- Which UI screens are affected
- Which permissions are affected — see [`PERMISSION_MATRIX.md`](01-product-discovery/PERMISSION_MATRIX.md)
- Which notifications are affected — see [`NOTIFICATION_CATALOG.md`](01-product-discovery/NOTIFICATION_CATALOG.md)

**If information is missing, ask questions instead of making assumptions.**

---

## STEP 3 — Follow Project Principles

Every response must uphold:

| Principle | Meaning |
|---|---|
| Child Safety First | When a trade-off exists, the option that better protects a child wins — even at the cost of convenience, performance, or elegance. |
| Parent Peace of Mind | Parents receive timely, accurate, non-alarming information about their child. |
| School Operational Efficiency | Staff workflows minimise manual effort and cognitive load. |
| Enterprise Scalability | Designs work for one school and for a group of five hundred. |
| Security by Design | Security is a design input, never a later addition. |
| Configuration over Hardcoding | Behaviour that varies by tenant, region, or policy lives in configuration. |
| Multi-Tenant Architecture | Tenant isolation is enforced structurally, not by convention. |
| Auditability | Every safety-relevant action is attributable to an actor and a time. |
| Maintainability | Optimise for the reader, not the writer. |
| Production Quality | No placeholders, no pseudo-production code, no "temporary" shortcuts. |

Full detail: [`PRODUCT_PRINCIPLES.md`](PRODUCT_PRINCIPLES.md) and [`ENGINEERING_PRINCIPLES.md`](ENGINEERING_PRINCIPLES.md).

---

## STEP 4 — Follow Engineering Standards

All solutions follow: Clean Architecture, SOLID, DRY, KISS, Feature-First Architecture, Repository Pattern, Dependency Injection, Modular Design, Layer Separation, Single Responsibility.

- **Never mix business logic into UI.**
- **Never duplicate business logic.**

See [`ENGINEERING_PRINCIPLES.md`](ENGINEERING_PRINCIPLES.md) and [`documentation/06-development/`](06-development/).

---

## STEP 5 — Before Coding

Explain, in this order: overall approach, business impact, database impact, API impact, UI impact, security impact, testing impact.

Then generate code.

---

## STEP 6 — After Coding

Verify: business rules · validation · authorization · error handling · logging · audit trail · performance · security · scalability · testability.

See [`documentation/06-development/DEFINITION_OF_DONE.md`](06-development/DEFINITION_OF_DONE.md), and [Current Exception — Flutter tests](#current-exception--flutter-tests) below.

---

## Current Exception — Flutter tests

**Do not write new Flutter test classes.** Delivery is focused on the backend API and database; widget tests written against an API shape that is still settling would be rewritten rather than reused.

Still applies:
- Existing Flutter tests stay and must keep passing.
- `flutter analyze` stays clean.
- `guardian_core` stays tested — it is pure Dart and every client depends on it.
- No business logic in widgets ([`ENGINEERING_PRINCIPLES.md`](ENGINEERING_PRINCIPLES.md) §8). That is what keeps the untested layer thin.
- Backend tests remain mandatory.

Revisit when the driver app starts consuming real endpoints. The 🔴 safety-critical screens — boarding, handover, SOS, reconciliation — are not covered by this and still require the coverage in [`SAFETY_CRITICAL_TEST_MATRIX.md`](07-testing/SAFETY_CRITICAL_TEST_MATRIX.md).

---

## Document Hierarchy

```
INSTRUCTIONS.md
   ↓
PROJECT_CHARTER.md
   ↓
Business Rules
   ↓
Feature Inventory
   ↓
System Design
   ↓
Database
   ↓
API
   ↓
UI
   ↓
Development
   ↓
Testing
   ↓
Deployment
```

If two documents conflict, **the higher-priority document wins**. Never invent requirements.

Full detail: [`documentation/00-governance/DOCUMENT_HIERARCHY.md`](00-governance/DOCUMENT_HIERARCHY.md).

---

## Response Format

This applies to **Standard and Architectural tier** requests (see STEP 0). When responding to one, cover:

1. Requirement Summary
2. Documents Referenced
3. Business Rules Applied
4. Proposed Solution
5. Impact Analysis
6. Implementation
7. Test Cases
8. Future Considerations

Never skip these sections unless the user explicitly requests only code.

**Trivial tier requests skip this format entirely** — see STEP 0. Manufacturing eight sections of write-up for a one-line fix is the failure mode STEP 0 exists to prevent, not a safer default.

---

## Documentation Rule

Whenever a new business rule, feature, module, or architectural decision is introduced, recommend:

- Which document should be updated
- Which new document should be created, if required
- Which existing documents may be affected

Architectural decisions are recorded as ADRs in [`documentation/00-governance/adr/`](00-governance/adr/).

Documentation is always the single source of truth.

---

## Quality Rule

- Never generate placeholder code.
- Never generate pseudo-production code.
- Never sacrifice architecture for speed.
- Always optimise for readability, maintainability, scalability, and long-term support.

---

## Project Memory

This is a long-term enterprise project. Maintain consistency with all previous architectural decisions. Never redesign an existing module without explaining why. Always extend the architecture rather than break it.

---

## Final Rule

For any question related to this project:

1. Read the project instructions.
2. Read the relevant documentation.
3. Explain your reasoning.
4. Follow project standards.
5. Produce enterprise-quality output.
6. **If documentation is missing, recommend creating or updating it before implementation.**
