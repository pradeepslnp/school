# MOD-01 — Tenancy Tables

**Owning module:** `com.guardian.tenancy` · **Implements:** ADR-0002 · **Rules:** BR-TEN-*

This module is the **reference implementation** — its tables, repositories, and use cases are the pattern other modules copy.

---

## `organizations`

The tenant. `tenant_id` on every other table references this.

| Column | Type | Notes |
|---|---|---|
| `code` | `VARCHAR(32)` | `NOT NULL`, globally unique, immutable once operational data exists (BR-TEN-007) |
| `name` | `VARCHAR(255)` | `NOT NULL` |
| `region_profile_id` | `UUID` | `NOT NULL` → `region_profiles` (ADR-0007) |
| `status` | `VARCHAR(24)` | `NOT NULL`, `ACTIVE` / `SUSPENDED` / `CLOSED` |
| `contact_email` | `VARCHAR(255)` | |
| `contact_phone` | `VARCHAR(32)` | |

Standard columns apply, **except `tenant_id`** — this table *is* the tenant.

```sql
CONSTRAINT uq_organizations_code       UNIQUE (code),
CONSTRAINT ck_organizations_status     CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED'))
```

**RLS is special-cased** — the policy compares `id`, not `tenant_id`. See [`RLS_POLICIES.md`](../RLS_POLICIES.md).

**Indexes:** `idx_organizations_status (status) WHERE status = 'ACTIVE'`

**Rules enforced structurally:** BR-TEN-001 (every scoped table FKs here), BR-TEN-007 (unique code)

---

## `schools`

Operational data belongs to a school, not directly to an organization.

| Column | Type | Notes |
|---|---|---|
| `organization_id` | `UUID` | `NOT NULL` → `organizations`, `ON DELETE RESTRICT` |
| `code` | `VARCHAR(32)` | `NOT NULL`, unique within organization |
| `name` | `VARCHAR(255)` | `NOT NULL` |
| `timezone` | `VARCHAR(64)` | `NOT NULL`, IANA identifier (BR-CFG-006) |
| `address_line1`, `address_line2`, `city`, `state`, `postal_code` | `VARCHAR` | Format per region profile |
| `latitude`, `longitude` | `NUMERIC(9,6)` | School geofence centre (ALT-003) |
| `geofence_radius_m` | `INTEGER` | `NOT NULL`, bounded by platform limits |
| `status` | `VARCHAR(24)` | `NOT NULL` |

```sql
CONSTRAINT uq_schools_org_code     UNIQUE (tenant_id, organization_id, code),
CONSTRAINT ck_schools_status       CHECK (status IN ('ACTIVE','INACTIVE')),
CONSTRAINT ck_schools_geofence     CHECK (geofence_radius_m BETWEEN 20 AND 2000),
CONSTRAINT fk_schools_organization FOREIGN KEY (organization_id)
    REFERENCES organizations(id) ON DELETE RESTRICT
```

`ON DELETE RESTRICT` implements BR-TEN-003 — a school cannot be orphaned or moved between organizations.

**Indexes:** `idx_schools_tenant_org (tenant_id, organization_id)`

**Rules:** BR-TEN-002 (last-school deletion refused — application), BR-TEN-003 (FK restrict), BR-CFG-006 (timezone stored)

**Note:** `timezone` is `NOT NULL` deliberately. Every displayed time depends on it, and a null would silently default to server time — wrong for any school outside the server's zone.

---

## `branches`

Optional subdivision (ADR-0002). Present so chains need no redesign; unused by most tenants.

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` |
| `code` | `VARCHAR(32)` | `NOT NULL`, unique within school |
| `name` | `VARCHAR(255)` | `NOT NULL` |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT uq_branches_school_code UNIQUE (tenant_id, school_id, code)
```

**Rules:** BR-TEN-005 — a null `branch_id` on any school-scoped record means "school-wide" and is valid.

---

## `school_calendars`

Operating days. Drives trip generation (BR-TRIP-011).

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` |
| `calendar_date` | `DATE` | `NOT NULL` |
| `day_type` | `VARCHAR(24)` | `NOT NULL`, `OPERATING` / `HOLIDAY` / `EXAM` / `SPECIAL` |
| `notes` | `TEXT` | |

```sql
CONSTRAINT uq_school_calendars_date UNIQUE (tenant_id, school_id, calendar_date),
CONSTRAINT ck_school_calendars_type CHECK (day_type IN ('OPERATING','HOLIDAY','EXAM','SPECIAL'))
```

**Indexes:** `idx_school_calendars_lookup (tenant_id, school_id, calendar_date)`

**Rules:** BR-TRIP-011 — non-operating days suppress trip generation.

---

## Reference Implementation Notes

This module demonstrates the patterns every other module follows:

| Pattern | Where to see it |
|---|---|
| Domain entity free of JPA | `tenancy/domain/School.java` |
| Separate persistence model | `tenancy/infrastructure/persistence/SchoolEntity.java` |
| Repository port in application | `tenancy/application/port/SchoolRepository.java` |
| Adapter in infrastructure | `tenancy/infrastructure/persistence/SchoolRepositoryAdapter.java` |
| Use case per operation | `tenancy/application/usecase/CreateSchoolUseCase.java` |
| Audit in the same transaction | Any write use case (BR-AUD-002) |
| RLS integration test | `tenancy/…/SchoolTenantIsolationTest.java` |

See [`PROJECT_STRUCTURE.md`](../../06-development/PROJECT_STRUCTURE.md).
