# MOD-16 / MOD-17 — Audit & Configuration Tables

**Owning modules:** `com.guardian.audit`, `com.guardian.config` · **Implements:** ADR-0007 · **Rules:** BR-AUD-*, BR-CFG-*

---

# MOD-16 — Audit 🔒

Strictly append-only. See [`AUDIT_AND_LOGGING.md`](../../02-system-design/AUDIT_AND_LOGGING.md).

## `audit_records`

| Column | Type | Notes |
|---|---|---|
| `actor_id` | `UUID` | Null for system actions |
| `actor_type` | `VARCHAR(24)` | `NOT NULL`, `USER` / `SYSTEM` / `DEVICE` / `PLATFORM_OPERATOR` |
| `actor_role` | `VARCHAR(32)` | Role **as held at the time** |
| `action` | `VARCHAR(64)` | `NOT NULL` — canonical verb, e.g. `HANDOVER_OVERRIDE` |
| `subject_type` | `VARCHAR(48)` | `NOT NULL` |
| `subject_id` | `UUID` | `NOT NULL` |
| `reason` | `TEXT` | **Required for overrides** (BR-AUD-004) |
| `source` | `VARCHAR(24)` | `NOT NULL`, `API` / `DEVICE` / `JOB` / `PLATFORM_OPS` |
| `correlation_id` | `UUID` | `NOT NULL` |
| `before_values`, `after_values` | `JSONB` | Changed fields only, sensitive values redacted |
| `occurred_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |

No `updated_at`, no `version`, no soft delete. The row never changes.

```sql
CONSTRAINT ck_audit_actor_type CHECK (
    actor_type IN ('USER','SYSTEM','DEVICE','PLATFORM_OPERATOR')),
CONSTRAINT ck_audit_source CHECK (source IN ('API','DEVICE','JOB','PLATFORM_OPS'))
```

### No foreign keys to subjects — deliberately

`subject_type` + `subject_id` is a polymorphic reference with **no FK constraint**. This is intentional: a subject may be archived or its table restructured while the audit trail must remain readable and intact. An FK would let a subject's lifecycle constrain its own audit record — precisely backwards.

### Append-only enforcement

Two independent controls, because the platform's evidentiary value rests on this:

```sql
GRANT INSERT, SELECT ON audit_records TO guardian_app;
-- no UPDATE, no DELETE

CREATE TRIGGER trg_audit_records_append_only
    BEFORE UPDATE OR DELETE ON audit_records
    FOR EACH ROW EXECUTE FUNCTION reject_mutation();
```

### The transactional guarantee

**The audit write shares the transaction of the change it records** (BR-AUD-002 🔴). If the audit write fails, the business change rolls back. The platform refuses an operation rather than performing it unrecorded.

This is the main reason the platform is a modular monolith with a shared database ([`ARCHITECTURE_OVERVIEW.md`](../../02-system-design/ARCHITECTURE_OVERVIEW.md)) — across service boundaries the guarantee would need a distributed transaction, or would be quietly dropped.

**Indexes**
```sql
idx_audit_subject     (tenant_id, subject_type, subject_id, occurred_at DESC)
idx_audit_actor       (tenant_id, actor_id, occurred_at DESC)
idx_audit_correlation (correlation_id)
idx_audit_overrides   (tenant_id, action, occurred_at DESC) WHERE reason IS NOT NULL
```

`idx_audit_overrides` serves the override register (AUD-003) — the report a school reviews when a parent questions a handover.

---

## `data_access_records`

Separate from `audit_records`: higher volume, different retention, different indexing (BR-IAM-012 🔴).

| Column | Type | Notes |
|---|---|---|
| `actor_id` | `UUID` | `NOT NULL` |
| `actor_role` | `VARCHAR(32)` | `NOT NULL` |
| `student_id` | `UUID` | `NOT NULL` |
| `access_type` | `VARCHAR(24)` | `NOT NULL`, `VIEW` / `LIST` / `EXPORT` / `REPORT` |
| `purpose` | `VARCHAR(64)` | The operation that caused the read |
| `record_count` | `INTEGER` | Set for `LIST` and `EXPORT` (BR-RPT-002) |
| `correlation_id` | `UUID` | `NOT NULL` |
| `occurred_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` |

Records every read of child personal data **by a non-guardian**. Guardians reading their own children are excluded — that is the expected case and would drown the signal.

**This is what makes insider misuse detectable rather than merely prohibited.** A staff member browsing children outside their operational need produces a visible pattern.

**Indexes:** `idx_data_access_student (tenant_id, student_id, occurred_at DESC)`, `idx_data_access_actor (tenant_id, actor_id, occurred_at DESC)`

---

# MOD-17 — Configuration

Implements ADR-0007: **no country, document type, or credential type is hardcoded.**

## `region_profiles`

Platform reference data — no `tenant_id`, no RLS.

| Column | Type | Notes |
|---|---|---|
| `code` | `VARCHAR(32)` | `NOT NULL` **UNIQUE** |
| `country_code` | `VARCHAR(8)` | `NOT NULL` — ISO 3166 |
| `default_locale` | `VARCHAR(16)` | `NOT NULL` |
| `phone_format_pattern` | `VARCHAR(128)` | `NOT NULL` |
| `address_format` | `JSONB` | `NOT NULL` — field order and requirements |
| `required_vehicle_documents` | `JSONB` | `NOT NULL` — document types and mandatory flags |
| `required_staff_credentials` | `JSONB` | `NOT NULL` |
| `default_retention_days` | `JSONB` | `NOT NULL` — per data class |

**Onboarding a new country is inserting a row here.** No deployment, no code change, no schema change — the test ADR-0007 sets for itself.

`JSONB` is appropriate here: these structures are read whole at tenant onboarding to seed defaults, never queried by internal field, and no business rule depends on a value inside them.

---

## `configuration_definitions`

The typed registry (BR-CFG-001). Platform reference data.

| Column | Type | Notes |
|---|---|---|
| `config_key` | `VARCHAR(128)` | `NOT NULL` **UNIQUE** |
| `value_type` | `VARCHAR(24)` | `NOT NULL`, `INTEGER` / `DECIMAL` / `BOOLEAN` / `STRING` / `DURATION` / `ENUM` |
| `default_value` | `TEXT` | `NOT NULL` |
| `min_value`, `max_value` | `NUMERIC` | **Platform floor and ceiling** |
| `allowed_values` | `JSONB` | For `ENUM` |
| `scope_level` | `VARCHAR(16)` | `NOT NULL`, `ORG` / `SCHOOL` — lowest level permitted |
| `is_safety_critical` | `BOOLEAN` | `NOT NULL DEFAULT false` |

```sql
CONSTRAINT uq_config_definitions_key UNIQUE (config_key),
CONSTRAINT ck_config_definitions_type CHECK (value_type IN (
    'INTEGER','DECIMAL','BOOLEAN','STRING','DURATION','ENUM'))
```

### `min_value` / `max_value` implement BR-CFG-003 🔴

Safety-critical configuration is bounded by platform floors and ceilings a tenant **cannot exceed** (BR-SAFE-007 🔴). A tenant may tighten a safety threshold; they may not loosen it past the floor.

`is_safety_critical` additionally gates the change behind `PERM-CONFIG-SAFETY-EDIT` and requires review.

This is where "Configuration over Hardcoding" yields to "Child Safety First" ([`PRODUCT_PRINCIPLES.md`](../../PRODUCT_PRINCIPLES.md) resolution order). A tenant may configure *which* handover verification methods are acceptable; they cannot configure verification away (BR-HAND-001 🔴).

---

## `configuration_values`

Tenant-scoped overrides. Tables store **deviations, not every key**.

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | → `schools`. Null = organization-wide. |
| `config_key` | `VARCHAR(128)` | `NOT NULL` → `configuration_definitions` |
| `config_value` | `TEXT` | `NOT NULL` |

```sql
CONSTRAINT uq_config_values UNIQUE (tenant_id, school_id, config_key)
```

Resolution order (BR-CFG-002): school → organization → region profile → platform default.

Every change is audited with old and new values (BR-CFG-004). Type, range, and floor validation happen on write, not on read — misconfiguration surfaces when it is made, not during a school run.

---

## `reference_data` and `localisation_resources`

Platform reference data, no RLS.

**`reference_data`** — `category` + `code` + `label_key`, valid values for document types, credential types, relationship types, incident types. Extended by migration, never by code enum.

**`localisation_resources`** — `locale` + `resource_key` + `value`. **All user-facing text** (BR-CFG-005). No string destined for a user is written inline in code.

---

## Verification

1. `UPDATE` or `DELETE` on `audit_records` raises an exception.
2. A failing audit write rolls back the business change.
3. An override submitted without a reason is rejected.
4. Every child-data read by a non-guardian writes a `data_access_records` row.
5. Every export writes a record including `record_count`.
6. A configuration value outside its definition's min/max is rejected on write.
7. A safety-critical configuration change without `PERM-CONFIG-SAFETY-EDIT` is refused.
8. Onboarding a tenant under a second region profile applies different phone validation, vehicle documents, and date formatting **with no code path selecting on country**.
9. No controller or domain class returns a user-facing string literal.
