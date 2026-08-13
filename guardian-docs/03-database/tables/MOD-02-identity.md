# MOD-02 — Identity & Access Tables

**Owning module:** `com.guardian.identity` · **Implements:** ADR-0006 · **Rules:** BR-IAM-*

---

## `users`

One row per person. A person may be both guardian and staff (BR-IAM-010) — one user, several roles.

| Column | Type | Notes |
|---|---|---|
| `email` | `VARCHAR(255)` | Unique within tenant where present |
| `phone` | `VARCHAR(32)` | Unique within tenant where present; format per region profile |
| `first_name`, `last_name` | `VARCHAR(128)` | `NOT NULL` |
| `preferred_locale` | `VARCHAR(16)` | `NOT NULL`, drives notification language |
| `status` | `VARCHAR(24)` | `NOT NULL`, `ACTIVE` / `INACTIVE` / `LOCKED` |
| `last_login_at` | `TIMESTAMPTZ` | |

```sql
CONSTRAINT uq_users_tenant_email CHECK/UNIQUE (tenant_id, lower(email)) WHERE email IS NOT NULL,
CONSTRAINT uq_users_tenant_phone UNIQUE (tenant_id, phone) WHERE phone IS NOT NULL,
CONSTRAINT ck_users_identifier    CHECK (email IS NOT NULL OR phone IS NOT NULL),
CONSTRAINT ck_users_status        CHECK (status IN ('ACTIVE','INACTIVE','LOCKED'))
```

`ck_users_identifier` matters: guardians authenticate by phone (many have no email), staff by email. At least one must exist.

**Indexes:** `idx_users_tenant_status (tenant_id, status) WHERE status = 'ACTIVE'`

---

## `user_credentials`

Separated from `users` so credential material is never loaded by ordinary user queries.

| Column | Type | Notes |
|---|---|---|
| `user_id` | `UUID` | `NOT NULL` → `users` |
| `credential_type` | `VARCHAR(24)` | `NOT NULL`, `PASSWORD` / `OTP` |
| `secret_hash` | `VARCHAR(255)` | `NOT NULL` — Argon2id |
| `expires_at` | `TIMESTAMPTZ` | Set for OTP |
| `consumed_at` | `TIMESTAMPTZ` | OTP single-use |
| `failed_attempts` | `INTEGER` | `NOT NULL DEFAULT 0` (BR-IAM-011) |
| `locked_until` | `TIMESTAMPTZ` | |

**Never** returned by any API. Not logged. See [`SECURITY_ARCHITECTURE.md`](../../02-system-design/SECURITY_ARCHITECTURE.md).

---

## `sessions`

Opaque refresh tokens, server-stored (ADR-0006).

| Column | Type | Notes |
|---|---|---|
| `user_id` | `UUID` | `NOT NULL` → `users` |
| `refresh_token_hash` | `VARCHAR(255)` | `NOT NULL` **UNIQUE** — hashed, never stored raw |
| `family_id` | `UUID` | `NOT NULL` — rotation lineage |
| `previous_session_id` | `UUID` | → `sessions` |
| `client_type` | `VARCHAR(24)` | `NOT NULL`, `PARENT_APP` / `DRIVER_APP` / `ADMIN_WEB` |
| `device_identifier` | `VARCHAR(255)` | |
| `issued_at`, `expires_at` | `TIMESTAMPTZ` | `NOT NULL` |
| `consumed_at` | `TIMESTAMPTZ` | Set on rotation — single-use |
| `is_revoked` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `revoked_reason` | `VARCHAR(64)` | |

```sql
CONSTRAINT uq_sessions_refresh_hash UNIQUE (refresh_token_hash)
```

**`family_id` implements reuse detection** (BR-IAM-009). Presenting an already-consumed refresh token means the token was stolen — the entire family is revoked and a security alert raised. Without `family_id` this attack is undetectable.

**Indexes:** `uq_sessions_refresh_hash`, `idx_sessions_user_active (tenant_id, user_id) WHERE NOT is_revoked`, `idx_sessions_family (family_id)`

**Rules:** BR-IAM-007, BR-IAM-009

---

## `roles`, `permissions`, `role_permissions`, `user_roles`

**`permissions` is platform reference data** — no `tenant_id`, no RLS, `SELECT` only for the application. Tenants assign permissions; they cannot invent them ([`PERMISSION_MATRIX.md`](../../01-product-discovery/PERMISSION_MATRIX.md)).

| Table | Key columns |
|---|---|
| `permissions` | `code` (`PERM-TRIP-VIEW`) UNIQUE, `area`, `description_key` |
| `roles` | `tenant_id`, `code`, `name`, `is_system_role` — unique `(tenant_id, code)` |
| `role_permissions` | `role_id`, `permission_id` — unique together |
| `user_roles` | `user_id`, `role_id` — unique together |

`is_system_role` marks the templates in the permission matrix. Tenants may define custom roles from the same permission set.

---

## `user_scopes`

Permission answers *what*; scope answers *which* (BR-IAM-006).

| Column | Type | Notes |
|---|---|---|
| `user_id` | `UUID` | `NOT NULL` → `users` |
| `scope_level` | `VARCHAR(24)` | `NOT NULL`, `PLATFORM` / `ORG` / `SCHOOL` / `ROUTE` |
| `scope_ref_id` | `UUID` | Null for `PLATFORM` and `ORG` |

```sql
CONSTRAINT ck_user_scopes_level CHECK (scope_level IN ('PLATFORM','ORG','SCHOOL','ROUTE')),
CONSTRAINT ck_user_scopes_ref   CHECK (
    (scope_level IN ('PLATFORM','ORG') AND scope_ref_id IS NULL)
 OR (scope_level IN ('SCHOOL','ROUTE') AND scope_ref_id IS NOT NULL))
```

`OWN_CHILDREN`, `TRIP`, and `SELF` are **not** stored here — they are derived at request time from `guardian_student_links` and `trip_staff`. Storing them would duplicate the source of truth and let the two diverge.

**Indexes:** `idx_user_scopes_user (tenant_id, user_id)`

---

## Verification

1. Refresh-token reuse revokes the whole `family_id` and raises an alert.
2. `user_credentials` never appears in any API response.
3. A user with neither email nor phone cannot be created.
4. A role cannot reference a permission code absent from `permissions`.
5. Permission changes take effect on the next request without a new token (BR-IAM-004).
6. Deactivating a user revokes all their sessions (BR-IAM-008).
