# guardian-identity (MOD-02)

Users, credentials, sessions, roles, permissions, and scope resolution. Implements
[ADR-0006](../../documentation/00-governance/adr/ADR-0006-authentication-model.md).

## Status

**Build wiring only.** No production code yet — the module is registered so its dependencies and
layering are fixed before implementation begins, and so the architecture tests apply from the first
commit.

This is deliberate scaffolding, not a placeholder: there are no stub classes, no
`UnsupportedOperationException`, and nothing that looks implemented but is not
([ENGINEERING_PRINCIPLES.md](../../documentation/ENGINEERING_PRINCIPLES.md) §15).

## Before implementing

Read, in order:

1. [ADR-0006](../../documentation/00-governance/adr/ADR-0006-authentication-model.md) — token model and why
   permissions are **not** embedded in tokens
2. [PERMISSION_MATRIX.md](../../documentation/01-product-discovery/PERMISSION_MATRIX.md) — the authoritative
   permission list; tenants assign permissions but cannot invent them
3. [MOD-02-identity.md](../../documentation/03-database/tables/MOD-02-identity.md) — table specifications
4. [AUTHENTICATION_API.md](../../documentation/04-api/AUTHENTICATION_API.md) — endpoint contracts

Then copy the structure of [`guardian-tenancy`](../guardian-tenancy/) — `domain/` → `application/`
→ `infrastructure/` → `interfaces/`. Do not invent a different layout.

## Rules this module owns

BR-IAM-001 … BR-IAM-012. Three carry particular weight:

| Rule | Why it matters |
|---|---|
| BR-IAM-004 🔴 | Permissions resolve **per request**, never from the token — a revoked permission takes effect on the next request, not at token expiry |
| BR-IAM-009 | Refresh-token reuse revokes the entire family; without `family_id` the theft is undetectable |
| BR-IAM-012 🔴 | Every non-guardian read of child data is logged — the control that makes insider misuse detectable |

## Definition of done

Remove `BR-IAM` from
[`traceability-baseline.txt`](../guardian-api/src/test/resources/traceability-baseline.txt) as part
of delivering this module. The traceability test will then require every `BR-IAM` rule to have a
test referencing it.
