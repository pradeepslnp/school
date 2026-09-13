# ADR-0016: Platform-operator elevation into an organization

**Status:** Accepted
**Date:** 2026-09-13
**Affects:** `guardian-api` (`infrastructure/tenant`, `infrastructure/security`), `admin` client, [`MULTI_TENANCY.md`](../../02-system-design/MULTI_TENANCY.md), [`PERMISSION_MATRIX.md`](../../01-product-discovery/PERMISSION_MATRIX.md), BR-TEN-004, BR-AUD-005, ADR-0001

## Context

`SUPER_ADMIN` holds `PERM-SCHOOL-VIEW`, `PERM-STUDENT-VIEW` and their siblings (`PERMISSION_MATRIX.md`), at `PLATFORM` scope — *"Across organizations. Platform operators only; always audited."* In practice the role could do almost none of it.

Tenant context is derived from the authenticated token, and row-level security scopes every query to it (ADR-0001). A platform operator's account lives in the platform organization, which owns no schools, students, vehicles or routes. `V12__organization_listing.sql` had already added one deliberately cross-tenant read — `list_organizations()`, a `SECURITY DEFINER` function owned by the `BYPASSRLS` role `guardian_platform_ops` — so the console could *list* every organization. Nothing equivalent existed for anything inside one.

The result was a console that offered a `SUPER_ADMIN` an organization picker that could never yield a school: every school-scoped screen gated its actions on a selected school, and none could be selected. The operator could create an organization and then do nothing inside it.

BR-TEN-004 (🔴) already anticipates the answer: *"No request may read or write data belonging to an organization other than the one in its authenticated context, **except through an explicitly permissioned platform-operations path, which is always audited**."* That path had not been built.

## Decision

A platform operator names the organization they are acting in, per request, in the header `X-Guardian-Organization`. When present and the caller holds `SUPER_ADMIN`, the request's tenant context becomes that organization; everything downstream — every repository, use case, and RLS policy — then works unchanged inside it, for reads **and** writes.

Three properties make this BR-TEN-004's permitted path rather than a hole in it:

- **Explicit.** Per request, never sticky. A request without the header acts in the operator's own organization like any other session. Nothing is inherited and nothing is implied.
- **Permissioned.** The header is honoured only for the platform role. Any other caller sending it is **refused** (`AUTH_PERMISSION_DENIED`), not silently downgraded to their own scope — an attempted escalation fails loudly. A malformed organization id is refused for the same reason: running a write somewhere other than where it was addressed is the worst available outcome.
- **Audited.** Every elevated request writes an audit record (`PLATFORM_ORG_ELEVATION`, actor type `PLATFORM_OPERATOR`, source `PLATFORM_OPS`) into **the target organization's own trail** — where someone asking "who outside this organization touched our records" will look (BR-AUD-005). Reads included; the noise is the point.

**Row-level security is untouched.** `guardian_app` still holds no `BYPASSRLS`, every policy still compares `tenant_id` to `app.tenant_id`, and an elevated request is confined to exactly the one organization it named. This widens *who may set that variable*, never what the variable does. No new `SECURITY DEFINER` function was added.

**Permissions resolve against the operator's home tenant.** `user_roles` is itself tenant-scoped, so resolving under the elevated context would find no roles and refuse every elevated request. `PermissionEnforcementInterceptor` therefore resolves permissions in the tenant the *account* lives in, and restores the ambient context immediately; data access stays scoped to the target. Organization-suspension checks deliberately keep using the ambient tenant — whether the organization being acted in is suspended is a question about the target.

The `admin` console sends the header while a platform operator has an organization selected, and clears it whenever the session ends.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| A `SECURITY DEFINER` read function per table, following `V12`'s pattern | Works, and is the obvious extension of what exists — but it multiplies with every table, covers reads only, and the user requirement is to *edit*. A dozen bypass functions is a dozen places for a policy to drift. |
| Grant `SUPER_ADMIN` a `BYPASSRLS` database role | Removes the boundary instead of crossing it under control. An elevated request would reach every organization at once rather than the single named one, and a bug would be unbounded. |
| Leave it as it was; platform operators use a per-organization account | Honest and safe, and it was the interim state. But it makes the `PLATFORM` scope in `PERMISSION_MATRIX.md` fiction, and it means credentials get shared to get work done — a worse security outcome than an audited elevation. |
| Sticky elevation held in the session/token | Fewer headers, but an operator would stay elevated without a per-request record of it, and a stale elevation would quietly apply to requests they did not think were cross-organization. |

## Consequences

**Positive**

- The `PLATFORM` scope now means what `PERMISSION_MATRIX.md` says it means.
- Every cross-organization access is discoverable from the affected tenant's own audit trail, naming the operator, the role, and the exact request line.
- No new bypass surface in the database; the change is confined to who may set the existing tenant variable.

**Negative / accepted cost**

- **A compromised `SUPER_ADMIN` account can now reach every organization's child records, not just the platform's.** That capability is what was asked for and what the permission matrix already promised, but it did not previously exist in practice. It raises the value of that account sharply — see Reversal Cost for the trigger this creates.
- Audit volume grows with platform-operator activity: one row per elevated request, reads included.
- The elevation audit opens its own transaction. `AuditPort` is `Propagation.MANDATORY` precisely so an audit record cannot commit independently of the change it describes; here the recorded event *is* the crossing, which is a fact the moment the context is set, so it commits with itself. Changes made under the elevation still write their own audit records atomically (BR-AUD-002).

**Neutral**

- The header is meaningless without a token that authorizes it, so its presence in a log or proxy leaks nothing.

## Reversal Cost

**Low.** Deleting `PlatformElevation` and its two call sites restores the previous behaviour exactly; no migration, no data shape, no schema grant to unwind. The client falls back to sending no header.

**Triggers for reconsideration:**

- Any credential compromise or suspected misuse of a `SUPER_ADMIN` account — this ADR's accepted cost is what makes that incident larger than it used to be.
- MFA for platform operators landing, which would materially reduce that cost and is worth requiring before this capability is used against production tenants.
- A second role acquiring `PLATFORM` scope — the role check here is deliberately a single literal, and a second holder should be a deliberate edit, not a surprise.
- Audit volume becoming unmanageable, which would be a signal that elevation is being used routinely rather than exceptionally.

## Verification

- Exercised end to end against a running API and the demo database: a `SUPER_ADMIN` without the header sees zero schools in another organization; with it, reads that organization's schools and students **and** creates a student in it; an `ORG_ADMIN` sending the header is refused `AUTH_PERMISSION_DENIED`; a malformed id is refused; and `audit_records` shows one `PLATFORM_ORG_ELEVATION` row per elevated request, in the target tenant, naming the request line.
- **No automated test asserts any of this**, in line with the repository's standing position on tests. That is a real gap for a 🔴 rule: the behaviour that keeps this inside BR-TEN-004 is the role check in `PlatformElevation.authorize` and the audit write in `TenantContextFilter`, and nothing in the build would fail if either were removed. `SAFETY_CRITICAL_TEST_MATRIX.md` already lists BR-TEN-004 rows; an elevation case belongs there whenever tests return.
