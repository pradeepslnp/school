# guardian-identity (MOD-02)

Users, credentials, sessions, roles, permissions, and scope resolution. Implements
[ADR-0006](../../documentation/00-governance/adr/ADR-0006-authentication-model.md).

## Status

**Delivered**, with one documented gap.

Sign-in — staff email + password (IAM-001), guardian phone + OTP (IAM-002) — plus token refresh
with rotation and reuse detection (IAM-003), self-service and administrator session management
(IAM-004), administrative user CRUD and invitations, role and scope assignment over the nine fixed
system-role templates (IAM-005, IAM-007), password reset (IAM-009), staff deactivation with session
and duty revocation (IAM-008), per-request permission resolution (BR-IAM-004 → V14), and child
data-access logging (IAM-010, enforced in MOD-03's `GetStudentUseCase`).

Not built: **IAM-006** (a tenant defining its own roles and choosing their permissions — the nine
templates resolve from `SystemRolePermissions` in code, and `role_permissions` exists only for
custom roles that no flow yet creates); **IAM-011** (school SSO — needs its own ADR); and the
read-time scope predicate for BR-IAM-006 across consuming modules, which is per-module work.

## Key references

1. [ADR-0006](../../documentation/00-governance/adr/ADR-0006-authentication-model.md) — token model and why
   permissions are **not** embedded in tokens
2. [PERMISSION_MATRIX.md](../../documentation/01-product-discovery/PERMISSION_MATRIX.md) — the authoritative
   permission list; tenants assign permissions but cannot invent them
3. [MOD-02-identity.md](../../documentation/03-database/tables/MOD-02-identity.md) — table specifications
4. [AUTHENTICATION_API.md](../../documentation/04-api/AUTHENTICATION_API.md) — endpoint contracts

Layout follows [`guardian-tenancy`](../guardian-tenancy/) — `domain/` → `application/` →
`infrastructure/` → `interfaces/`.

## Rules this module owns

BR-IAM-001 … BR-IAM-012. Three carry particular weight:

| Rule | Why it matters |
|---|---|
| BR-IAM-004 🔴 | Permissions resolve **per request**, never from the token — a revoked permission takes effect on the next request, not at token expiry |
| BR-IAM-009 | Refresh-token reuse revokes the entire family; without `family_id` the theft is undetectable |
| BR-IAM-012 🔴 | Every non-guardian read of child data is logged — the control that makes insider misuse detectable |

## Definition of done

`BR-IAM` is off
[`traceability-baseline.txt`](../guardian-api/src/test/resources/traceability-baseline.txt) except
**BR-IAM-010**, which has no single enforcement point and needs a test exercising one user holding
both a guardian and a staff role — deferred under the current no-test policy, listed rather than
dropped.
