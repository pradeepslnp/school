# ADR-0003: Flutter Web for the administration client

**Status:** Proposed — *weakest of the current assumptions; see Reversal Cost*
**Date:** 2026-08-03
**Affects:** `guardian-admin-web/`, [`ADMIN_WEB.md`](../../05-ui/ADMIN_WEB.md), [`DESIGN_SYSTEM.md`](../../05-ui/DESIGN_SYSTEM.md)

## Context

The platform needs three clients: a parent mobile app, a driver/attendant mobile app, and a web administration console for transport managers and school admins.

Flutter is the confirmed choice for the two mobile apps. The admin console's technology was not specified.

The admin console is data-dense: tables with thousands of rows, bulk import, filtering, route editing on a map, and reporting. This is the workload where Flutter Web is least comfortable and a DOM-based stack is most comfortable.

## Decision

**Flutter Web, using the CanvasKit renderer, sharing the `guardian_core` package with the mobile apps.**

Rationale: one language and one domain layer across all three clients. The API client, models, error handling, validation, and permission logic in `guardian_core` are written once and reused, rather than reimplemented in TypeScript and then drifting from the Dart implementations.

For a small team, eliminating a second language and a second implementation of the domain model is worth more than the rendering advantages of a DOM stack.

## Alternatives Considered

| Alternative | Why rejected — *for now* |
|---|---|
| React + TypeScript | Better for data-dense admin UIs: mature table/grid ecosystem, superior text rendering, smaller initial payload, better SEO and accessibility defaults. Rejected only because it duplicates the domain layer in a second language. **This is the strongest alternative and the most likely successor.** |
| Server-rendered (Thymeleaf) | Simplest deployment and excellent accessibility, but a poor fit for live map tracking and interactive route editing. |
| Two clients: Flutter Web plus a React reporting console | Worst of both — two stacks *and* a split admin experience. |

## Consequences

**Positive**
- One language across backend-adjacent client code; one shared domain package.
- Consistent design system across all three clients.
- Developers move between clients without context switching.

**Negative / accepted cost**
- **Initial load is large.** CanvasKit adds several megabytes; unacceptable for a consumer product, tolerable for an authenticated internal console on desk-grade connections.
- **Accessibility is weaker than DOM.** Flutter Web's semantics layer is real but less capable than native HTML. Given [`ACCESSIBILITY.md`](../../05-ui/ACCESSIBILITY.md) is a stated requirement, this is the most serious cost of this decision.
- **Text selection, browser find, and deep-linking** need deliberate work rather than coming free.
- Large data grids need virtualisation implemented rather than adopted from a mature library.

**Neutral**
- The parent and driver apps are unaffected either way.

## Reversal Cost

**Moderate, and deliberately kept so.** Mitigations that preserve the exit:

1. All domain logic, API access, and models live in `guardian_core` — but `guardian_core` must not depend on Flutter widgets. A replacement React client would reimplement the view layer only, and could consume the same documented API contracts.
2. No admin business logic in widgets ([`ENGINEERING_PRINCIPLES.md`](../../ENGINEERING_PRINCIPLES.md) §8).

**Reconsider when any of these occur:** an accessibility audit fails on the console; admin users report load times as a material complaint; or the first large data grid requires more effort to virtualise than a React rewrite of that screen would cost.

## Verification

1. An accessibility audit of the admin console against [`ACCESSIBILITY.md`](../../05-ui/ACCESSIBILITY.md) before the console is declared production-ready. **A failure here triggers reconsideration of this ADR, not a waiver of the requirement.**
2. A dependency test asserts `guardian_core` does not import `package:flutter/material.dart`, keeping the domain layer portable.
3. Initial-load budget tracked in CI: fail if the console's first meaningful paint on a simulated 4G connection exceeds the budget in [`ADMIN_WEB.md`](../../05-ui/ADMIN_WEB.md).
