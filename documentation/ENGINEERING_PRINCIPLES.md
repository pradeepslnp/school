# ENGINEERING PRINCIPLES

**Document tier:** 0 — Governance
**Status:** Active
**Applies to:** backend, mobile apps, admin web, infrastructure

---

## 1. Clean Architecture

Dependencies point inward. Domain knows nothing about infrastructure.

```
┌──────────────────────────────────────────────┐
│  Interface        controllers, DTOs, mappers │
│  ┌────────────────────────────────────────┐  │
│  │  Application    use cases, ports        │  │
│  │  ┌──────────────────────────────────┐   │  │
│  │  │  Domain   entities, value objects │   │  │
│  │  │           domain services, rules  │   │  │
│  │  └──────────────────────────────────┘   │  │
│  └────────────────────────────────────────┘  │
│  Infrastructure  JPA, messaging, providers   │
└──────────────────────────────────────────────┘
        Infrastructure implements Application ports
```

**Rules**
- Domain classes import no framework annotations beyond what is unavoidable, and never import Spring, JPA, or HTTP types.
- Application defines **ports** (interfaces). Infrastructure provides **adapters**.
- Interface layer maps DTO ↔ domain. Domain objects are never serialised directly to clients.

**Enforcement:** an ArchUnit test suite in `guardian-common` fails the build on violations. See [`documentation/06-development/ARCHITECTURE_ENFORCEMENT.md`](06-development/ARCHITECTURE_ENFORCEMENT.md).

---

## 2. Feature-First (Modular) Organisation

Package by feature, then by layer — never the reverse.

```
com.guardian.tenancy
  ├── domain/
  ├── application/
  ├── infrastructure/
  └── interfaces/
```

Not `com.guardian.controllers`, `com.guardian.services`.

A module owns its tables. Cross-module access goes through the owning module's application layer, never by reaching into another module's repository or table.

---

## 3. SOLID

| Principle | Applied as |
|---|---|
| Single Responsibility | A use case class does one thing. If its name needs "And", split it. |
| Open/Closed | New notification channels, GPS device types, and alert rules are added as new implementations, not by editing a switch. |
| Liskov Substitution | Any `NotificationChannel` works wherever the port is used, including in tests. |
| Interface Segregation | Narrow ports. A use case that only reads declares a read port. |
| Dependency Inversion | Application depends on abstractions; Spring wires concretions at the edge. |

---

## 4. Repository Pattern

- Repositories are defined as **domain-facing interfaces in the application layer** and implemented in infrastructure.
- Repository methods speak the domain's language (`findActiveTripsForVehicle`), not the ORM's.
- No JPA entity leaves the infrastructure layer. Persistence models and domain models are separate types with explicit mapping.

**Why the separation is worth its cost here:** safety records are append-only and will outlive the current ORM choice. Coupling domain rules to JPA would make retention, partitioning, and archival changes far more expensive later.

---

## 5. Dependency Injection

- Constructor injection only. No field injection, no `@Autowired` on fields.
- All dependencies are explicit and final.
- No static mutable state. No service locators.

---

## 6. DRY — With Judgement

Business logic is defined once, in the domain. Two pieces of code that look alike but change for different reasons are **not** duplication; do not couple them.

The rule that matters: **a business rule has exactly one implementation.** If a rule is checked in the UI, it is checked for user experience only — the server enforces it.

---

## 7. KISS

Prefer the simplest design that satisfies the requirement and its stated scalability target. Do not build for hypothetical requirements. When adding indirection, name the concrete second implementation it enables — if none exists, do not add it.

---

## 8. Layer Separation

**Never mix business logic into UI.** Flutter widgets render state and emit intents. Decisions are made in the domain layer of the app, and authoritative decisions are made on the server.

**Never duplicate business logic.** A rule implemented on both client and server is a rule that will diverge.

---

## 9. Multi-Tenancy Is Structural

- Every tenant-scoped table carries `tenant_id`.
- PostgreSQL Row-Level Security is the enforcement boundary; application filtering is a convenience, not the control.
- Tenant context is established once per request and propagated; it is never passed as a method parameter that a developer could forget.
- A repository that can return cross-tenant rows must be explicitly named and permission-gated.

See [`documentation/02-system-design/MULTI_TENANCY.md`](02-system-design/MULTI_TENANCY.md).

---

## 10. Security by Design

- Authorisation decided server-side, inside tenant scope, on every request.
- Deny by default. A new endpoint without an explicit permission fails closed.
- Validate at the boundary; never trust client-supplied identifiers.
- Secrets come from the environment or a secret manager, never from source.
- Child PII is minimised, encrypted at rest and in transit, and access-audited.

---

## 11. Auditability

Every safety-relevant state change writes an audit record: actor, action, subject, timestamp, source, and reason where applicable. Audit writes participate in the same transaction as the change. Audit records are append-only.

---

## 12. Error Handling

- Domain failures are typed domain exceptions, not strings or booleans.
- One global exception handler maps domain failures to the standard error envelope in [`documentation/04-api/ERROR_CATALOG.md`](04-api/ERROR_CATALOG.md).
- Never swallow an exception. Never log and rethrow the same error at multiple layers.
- Error messages returned to clients never leak internal detail.

---

## 13. Observability

Structured JSON logs with correlation ID and tenant ID on every entry. No child PII in logs. Metrics for every safety-critical path. Traces across ingestion → processing → notification.

---

## 14. Testing

| Level | Scope |
|---|---|
| Unit | Domain rules, in isolation, no Spring context |
| Integration | Repository + database via Testcontainers, including RLS enforcement |
| Contract | API request/response shape against documented schema |
| End-to-end | Critical safety journeys only |

Every business rule ID in [`BUSINESS_RULES.md`](01-product-discovery/BUSINESS_RULES.md) has at least one test referencing it by ID.

---

## 15. Production Quality

No placeholder code. No `TODO` in merged code without a linked issue. No commented-out blocks. No pseudo-production shortcuts.

If something cannot be finished properly, it is not merged — it is documented as not done.
