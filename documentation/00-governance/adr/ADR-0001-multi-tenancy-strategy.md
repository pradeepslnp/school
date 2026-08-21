# ADR-0001: Multi-tenancy via shared schema with Row-Level Security

**Status:** Proposed
**Date:** 2026-08-03
**Affects:** all database tables, all repositories, [`MULTI_TENANCY.md`](../../02-system-design/MULTI_TENANCY.md), [`RLS_POLICIES.md`](../../03-database/RLS_POLICIES.md)

## Context

The charter commits to tenant isolation being *structural, not conventional* ([`PROJECT_CHARTER.md`](../../PROJECT_CHARTER.md) §6.1) and to a zero-tolerance target for cross-tenant leakage.

Forces:

- Tenants are school groups; expected scale is hundreds of organizations, each with thousands of students, plus high-volume position data.
- The data is child PII. A cross-tenant leak is a safety and regulatory incident, not merely a bug.
- A small operations team must run migrations, backups, and schema changes.
- Some tenants will be single schools; some will be chains of hundreds.

The risk this decision must address: **isolation that depends on every developer remembering a `WHERE tenant_id = ?` clause will eventually fail.** One forgotten predicate in one query is a breach.

## Decision

**Shared database, shared schema, `tenant_id` discriminator column on every tenant-scoped table, with PostgreSQL Row-Level Security as the enforcement boundary.**

- Every tenant-scoped table has `tenant_id UUID NOT NULL` and an RLS policy filtering on a session variable (`app.tenant_id`).
- The application sets that session variable once per request from the authenticated principal, in a transaction-scoped manner.
- The application's runtime database role is **not** the table owner and does **not** hold `BYPASSRLS`.
- Application-level filtering may exist for query efficiency, but it is never the control. RLS is the control.
- Cross-tenant access (platform operations, support) uses a separate, explicitly named, permission-gated, audited path.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Database per tenant | Strongest isolation, but migration and connection-pool cost scale linearly with tenant count. Unworkable for hundreds of tenants with a small ops team; cross-tenant platform reporting becomes a data-warehouse problem on day one. |
| Schema per tenant | Better isolation than shared schema, but migrations must run per schema and connection pooling degrades. Still fails to protect against application bugs within a schema. Reconsider if a tenant contractually requires physical separation. |
| Shared schema, application-level filtering only | The common industry approach and the cheapest to build. Rejected because it makes isolation depend on developer discipline in every query forever. Directly contradicts the charter's "structural, not conventional" commitment. |
| Shared schema + RLS + separate schema for the largest tenants | Hybrid complexity without a present requirement. Revisit only when a tenant demands it contractually. |

## Consequences

**Positive**
- A forgotten `WHERE` clause returns zero rows instead of another tenant's children.
- One migration path, one backup strategy, one connection pool.
- Cross-tenant platform analytics remain straightforward.

**Negative / accepted cost**
- Every query pays a small RLS predicate cost; indexes must lead with `tenant_id`.
- Connection pooling requires care: the session variable must be set per transaction and cleared, or a pooled connection could carry the wrong tenant. This is the primary implementation risk and is covered by a dedicated integration test.
- Developers must understand RLS to debug "missing" rows.
- A schema-level mistake (a table created without RLS enabled) is a silent hole — mitigated by an automated check.

**Neutral**
- `tenant_id` is the organization ID, not the school ID. School-level scoping is authorisation, layered above tenant isolation.

## Reversal Cost

**High.** Moving to schema- or database-per-tenant later requires a data migration per tenant and changes to connection management. Reconsider if: a tenant contractually requires physical isolation; or a single tenant's position-data volume degrades shared-table performance beyond what partitioning solves.

## Verification

1. An integration test asserts that a query executed under tenant A's session variable returns zero rows written under tenant B — for every tenant-scoped repository.
2. A migration test asserts that every table carrying a `tenant_id` column has RLS **enabled and forced**, failing the build if a new table is added without a policy.
3. A test asserts the application role lacks `BYPASSRLS`.
4. A connection-pool test asserts the tenant session variable does not leak between sequential transactions on the same physical connection.
