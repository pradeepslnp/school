# MULTI-TENANCY

**Document tier:** 2 — System Design
**Status:** Active
**Implements:** ADR-0001, ADR-0002 · **Enforces:** BR-TEN-001 … BR-TEN-007

---

## Model

Shared database, shared schema, `tenant_id` discriminator, **PostgreSQL Row-Level Security as the enforcement boundary**.

```
Organization  ← the tenant; tenant_id refers to this
   └── School      ← operational data lives here
         └── Branch    ← optional (ADR-0002)
```

`tenant_id` is always the **organization** ID. School and branch scoping is *authorisation*, layered above isolation. Conflating the two is the most common mistake in this design — isolation says "which data exists for you at all"; authorisation says "which of it you may see".

---

## The Two Layers

| Layer | Mechanism | Fails how |
|---|---|---|
| **Isolation** | RLS on `tenant_id` | Returns zero rows |
| **Authorisation** | Permission + scope in the application | Returns `403` |

A bug in the application layer produces a wrong answer *within* a tenant. It cannot produce another tenant's data. That is the property ADR-0001 buys.

---

## Tenant Context Propagation

```
JWT (carries tenant_id)                              ADR-0006
      ▼
TenantContextFilter
      ▼
TenantContext  (request-scoped holder)
      ▼
Transaction begins
      ▼
SET LOCAL app.tenant_id = '<uuid>'
      ▼
Every query in the transaction is RLS-filtered
      ▼
Transaction ends — SET LOCAL expires automatically
```

**`SET LOCAL`, not `SET`.** The value is scoped to the transaction and vanishes on commit or rollback. This is what makes the setting safe with a connection pool: a pooled connection cannot carry a stale tenant into the next request. Using `SET` here would be a cross-tenant leak waiting to happen, and is explicitly forbidden.

### Non-request contexts

| Context | How tenant is established |
|---|---|
| Scheduled job | Iterates tenants explicitly; sets context per tenant, per transaction |
| Event handler | Tenant travels in the event payload; set before handling |
| Ingestion | Resolved from the device's vehicle registration |
| Platform operation | Explicit, permissioned, audited elevation (BR-TEN-004) |

A job that forgets to set context reads nothing — it does not read everything. The failure mode is safe by construction.

---

## Database Enforcement

Every tenant-scoped table:

```sql
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE students FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON students
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid)
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::uuid);
```

Four details that matter:

1. **`FORCE`** — without it, the table owner bypasses the policy. The migration role owns tables; forcing ensures no role escapes by accident.
2. **`WITH CHECK`** — blocks *writing* a row into another tenant, not just reading one. A policy with only `USING` is half a control.
3. **`current_setting(..., true)`** — the `true` returns null rather than erroring when unset. With a `NOT NULL` comparison this yields zero rows: **unset context means no access**, which is the correct default.
4. **The application role is not the owner and lacks `BYPASSRLS`.** Verified by test.

Full policy list: [`RLS_POLICIES.md`](../03-database/RLS_POLICIES.md).

### Non-tenant-scoped tables

Platform reference data — countries, locales, region profiles, permission definitions — carries no `tenant_id` and no RLS. These are read-only to tenants and managed by platform operations.

---

## Scope Resolution

Once isolation guarantees "this organization's data", authorisation narrows further:

```
PLATFORM      across organizations — audited elevation only
   ▼
ORG           all schools in the organization
   ▼
SCHOOL        assigned school(s)
   ▼
ROUTE         assigned routes
   ▼
TRIP          the currently active trip only
   ▼
OWN_CHILDREN  actively linked students          BR-IAM-005
   ▼
SELF
```

Scope is resolved per request (BR-IAM-004) and applied as a predicate in the application layer. See [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md).

---

## The Platform Operations Path

The single deliberate exception to isolation (BR-TEN-004).

```
Operator requests tenant access
      ▼
PERM-PLATFORM-TENANT-ACCESS checked
      ▼
Justification REQUIRED — no justification, no access
      ▼
Audit record written BEFORE access is granted    AUD-004
      ▼
Time-boxed elevated context established
      ▼
Every read during elevation is logged            BR-IAM-012
      ▼
Elevation expires automatically
```

This path exists because support is impossible without it. It is instrumented more heavily than any other path in the system precisely because it is the one hole.

---

## Indexing

Every tenant-scoped index leads with `tenant_id`:

```sql
CREATE INDEX idx_students_tenant_school ON students (tenant_id, school_id);
```

The RLS predicate applies to every query, so an index not leading with `tenant_id` will not serve it well. See [`INDEXING_AND_PARTITIONING.md`](../03-database/INDEXING_AND_PARTITIONING.md).

---

## Onboarding a Tenant

1. Create the organization (TEN-001).
2. Attach a region profile — supplies defaults for documents, credentials, formats, retention (ADR-0007).
3. Create at least one school (BR-TEN-002) with its time zone.
4. Seed default roles from platform templates.
5. Create the first admin user.
6. Seed notification templates in the tenant's locales.

**No deployment, no code change, no schema change.** A new country is a new region profile row (ADR-0007).

---

## Verification

Every item is an automated test — this design is only as good as its enforcement.

| # | Test |
|---|---|
| 1 | For every tenant-scoped repository: data written under tenant A returns zero rows when read under tenant B. |
| 2 | Every table with a `tenant_id` column has RLS **enabled and forced** — fails the build when a new table is added without a policy. |
| 3 | Every RLS policy declares both `USING` and `WITH CHECK`. |
| 4 | The application role lacks `BYPASSRLS` and does not own the tables. |
| 5 | Two sequential transactions on the same pooled connection with different tenants do not leak context. |
| 6 | With no tenant context set, tenant-scoped reads return zero rows. |
| 7 | A write attempting to insert a foreign `tenant_id` is rejected by `WITH CHECK`. |
| 8 | Platform elevation without a justification is refused, and successful elevation writes an audit record before the first read. |
