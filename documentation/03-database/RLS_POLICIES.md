# ROW-LEVEL SECURITY POLICIES

**Document tier:** 3 — Database
**Status:** Active
**Implements:** ADR-0001 · **Enforces:** BR-TEN-004 🔴

This is the enforcement boundary for tenant isolation. If this document's rules are not followed exactly, the platform's primary security guarantee does not hold.

---

## Roles

| Role | Purpose | RLS |
|---|---|---|
| `guardian_owner` | Owns schema objects; used only by migrations | Bypassed — hence `FORCE` on every table |
| `guardian_app` | The application's runtime role | **Subject to RLS.** No `BYPASSRLS`. Not the owner. |
| `guardian_readonly` | Reporting replica reads | Subject to RLS |

```sql
CREATE ROLE guardian_app LOGIN PASSWORD :'app_password' NOBYPASSRLS;
```

A test asserts `guardian_app` has neither `BYPASSRLS` nor `SUPERUSER` and does not own tables. **This is checked because it is the single misconfiguration that silently removes all isolation.**

---

## The Standard Policy

Applied to **every** table carrying `tenant_id`:

```sql
ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;
ALTER TABLE <table> FORCE  ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON <table>
    FOR ALL
    TO guardian_app
    USING      (tenant_id = current_setting('app.tenant_id', true)::uuid)
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::uuid);
```

### Why each clause is exactly this

| Clause | Consequence of omitting it |
|---|---|
| `FORCE` | The owning role bypasses the policy. Any process connecting as owner reads everything. |
| `WITH CHECK` | Reads are protected; **writes are not**. A bug could insert a row bearing another tenant's `tenant_id`. |
| `current_setting(..., true)` | Without `true`, an unset variable raises an error instead of returning null. Errors get caught and worked around; null yields zero rows. |
| `FOR ALL` | Separate per-command policies invite one being forgotten. |
| Unset ⇒ zero rows | `NULL = uuid` is null, never true. **No tenant context means no access** — the safe default. |

---

## Setting Tenant Context

```sql
SET LOCAL app.tenant_id = '550e8400-e29b-41d4-a716-446655440000';
```

**`SET LOCAL`, never `SET`.** `SET LOCAL` is transaction-scoped and expires on commit or rollback. Plain `SET` persists for the session — and with a connection pool, the session outlives the request, so the next tenant to borrow that connection inherits the previous tenant's context.

That is a cross-tenant data leak with no error, no log entry, and no test failure unless specifically tested for. Verification test 5 exists solely for this.

Application implementation: `TenantContextFilter` → transaction listener issuing `SET LOCAL` at transaction start ([`MULTI_TENANCY.md`](../02-system-design/MULTI_TENANCY.md)).

---

## Tables With Policies

Every table listed under a tenant-scoped module in [`DATA_MODEL_OVERVIEW.md`](DATA_MODEL_OVERVIEW.md) carries the standard policy. Named explicitly so omissions are visible:

**Tenancy** `schools` · `branches` · `school_calendars`
**Identity** `users` · `user_credentials` · `sessions` · `roles` · `role_permissions` · `user_roles` · `user_scopes`
**Students** `students` · `student_classes` · `student_credentials`
**Guardians** `guardians` · `guardian_student_links` · `authorised_pickup_persons` · `custody_restrictions`
**Fleet** `vehicles` · `vehicle_documents` · `devices`
**Staff** `transport_staff` · `staff_credentials` · `duty_assignments`
**Routes** `routes` · `stops` · `route_student_assignments`
**Trips** `trips` · `trip_manifests` · `trip_manifest_amendments` · `trip_staff`
**Boarding** `boarding_events` · `handovers` · `reconciliations` · `reconciliation_items`
**Tracking** `position_history` *(and every partition)* · `trip_etas`
**Alerts** `alert_rules` · `alerts`
**Notification** `notification_templates` · `notification_preferences` · `notifications` · `notification_deliveries`
**Incidents** `sos_alerts` · `incidents` · `incident_escalations`
**Absence** `absence_declarations`
**Audit** `audit_records` · `data_access_records`
**Configuration** `configuration_values`

### `organizations` — the special case

`organizations` is the tenant table itself. Its policy compares `id`, not `tenant_id`:

```sql
CREATE POLICY tenant_isolation ON organizations
    FOR ALL TO guardian_app
    USING      (id = current_setting('app.tenant_id', true)::uuid)
    WITH CHECK (id = current_setting('app.tenant_id', true)::uuid);
```

### Tables with no RLS

Platform reference data, readable by all tenants, writable only by migrations and platform operations:

`permissions` · `region_profiles` · `configuration_definitions` · `reference_data` · `localisation_resources`

These carry no `tenant_id`. `guardian_app` holds `SELECT` only.

---

## Partitioned Tables

RLS on a partitioned parent **does not automatically cover partitions created later**. Since `position_history` partitions are created by a scheduled job, that job must apply the policy to each new partition.

The partition-creation function applies `ENABLE`/`FORCE` and the policy as part of creating the partition, and verification test 2 covers partitions as well as base tables. A partition created without a policy would expose every tenant's vehicle positions for that day.

---

## Platform Operations

The one permitted crossing (BR-TEN-004). It does **not** disable RLS — it sets context to the target tenant after an audited elevation:

```
PERM-PLATFORM-TENANT-ACCESS verified
   → justification required
   → audit record written BEFORE access
   → SET LOCAL app.tenant_id = <target org>
   → time-boxed; every read logged
```

There is no code path that turns RLS off, and none may be added. Genuine cross-tenant platform reporting runs against dedicated aggregate views owned by platform operations, not by lifting isolation.

---

## Adding a Table

1. Add `tenant_id UUID NOT NULL REFERENCES organizations(id)`.
2. `ENABLE` **and** `FORCE` row level security.
3. Create the standard policy with both `USING` and `WITH CHECK`.
4. Add the table to the list above.
5. Index leading with `tenant_id`.

Steps 2–3 are verified automatically. A migration adding a `tenant_id` table without a forced policy **fails the build** — this is the guard that keeps the guarantee true as the schema grows, and it matters more than any individual policy.

---

## Verification

| # | Test |
|---|---|
| 1 | Data written under tenant A returns zero rows read under tenant B — for every tenant-scoped repository. |
| 2 | Every table (and partition) with a `tenant_id` column has RLS enabled **and forced**. |
| 3 | Every policy declares both `USING` and `WITH CHECK`. |
| 4 | `guardian_app` lacks `BYPASSRLS` and `SUPERUSER` and owns no tables. |
| 5 | Two sequential transactions on one pooled connection with different tenants do not leak context. |
| 6 | With no context set, every tenant-scoped read returns zero rows. |
| 7 | Inserting a row with a foreign `tenant_id` is rejected by `WITH CHECK`. |
| 8 | A newly created `position_history` partition carries the policy. |
| 9 | No code path issues `SET` (session-scoped) for `app.tenant_id` — only `SET LOCAL`. |
