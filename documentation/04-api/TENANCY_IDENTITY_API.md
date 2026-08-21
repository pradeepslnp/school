# TENANCY & IDENTITY API

**Document tier:** 4 — API
**Modules:** MOD-01, MOD-02 · **Features:** TEN-001…005, IAM-005…008, IAM-010

Standards: [`API_STANDARDS.md`](API_STANDARDS.md) · Errors: [`ERROR_CATALOG.md`](ERROR_CATALOG.md) · Permissions: [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md)

---

## Organizations

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/organizations` | TEN-001 | `PERM-ORG-CREATE` | BR-TEN-001, BR-TEN-007 |
| `GET` | `/organizations/{id}` | TEN-001 | `PERM-ORG-VIEW` | BR-TEN-004 |
| `PATCH` | `/organizations/{id}` | TEN-001 | `PERM-ORG-EDIT` | BR-TEN-007 |
| `POST` | `/organizations/{id}/suspend` | TEN-004 | `PERM-ORG-SUSPEND` | BR-TEN-006 |
| `POST` | `/organizations/{id}/reactivate` | TEN-004 | `PERM-ORG-SUSPEND` | BR-TEN-006 |

### `POST /organizations`

```json
{
  "code": "GREENWOOD",
  "name": "Greenwood Education Group",
  "regionProfileCode": "IN",
  "contactEmail": "ops@greenwood.example",
  "contactPhone": "+919876543210"
}
```

`regionProfileCode` supplies defaults for phone formats, required vehicle documents, staff credential types, address format, and retention (ADR-0007). **Onboarding a new country requires no code change** — only a region profile row.

`code` is immutable once operational data exists (BR-TEN-007).

**Errors:** `ORG_CODE_ALREADY_EXISTS` (409)

### Suspension

`POST /organizations/{id}/suspend` blocks all user access except platform operations. It **destroys no data and does not stop safety recording for trips already started** (BR-TEN-006) — a suspension for non-payment must not strand a bus mid-route with no way to record boarding.

---

## Schools

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/schools` | TEN-002 | `PERM-SCHOOL-CREATE` | BR-TEN-002, BR-TEN-003 |
| `GET` | `/schools` | TEN-002 | `PERM-SCHOOL-VIEW` | BR-IAM-006 |
| `GET` | `/schools/{id}` | TEN-002 | `PERM-SCHOOL-VIEW` | |
| `PATCH` | `/schools/{id}` | TEN-002 | `PERM-SCHOOL-EDIT` | BR-TEN-003 |
| `DELETE` | `/schools/{id}` | TEN-002 | `PERM-SCHOOL-EDIT` | BR-TEN-002 |

```json
{
  "organizationId": "…",
  "code": "GW-MAIN",
  "name": "Greenwood Main Campus",
  "timezone": "Asia/Kolkata",
  "address": { "line1": "…", "city": "…", "postalCode": "…" },
  "latitude": 28.612900, "longitude": 77.229000,
  "geofenceRadiusM": 150
}
```

**`timezone` is required.** Every displayed time depends on it (BR-CFG-006); a default to server time would be wrong for any school outside the server's zone.

`DELETE` on the last school of an active organization returns `422 ORG_LAST_SCHOOL_CANNOT_BE_REMOVED` (BR-TEN-002). Schools cannot move between organizations — `SCHOOL_CANNOT_CHANGE_ORGANIZATION` (BR-TEN-003).

---

## Branches

| Method | Path | Feature | Permission |
|---|---|---|---|
| `POST` | `/schools/{schoolId}/branches` | TEN-003 | `PERM-SCHOOL-EDIT` |
| `GET` | `/schools/{schoolId}/branches` | TEN-003 | `PERM-SCHOOL-VIEW` |
| `PATCH` | `/branches/{id}` | TEN-003 | `PERM-SCHOOL-EDIT` |

Optional (ADR-0002). Tenants not using branches never call these; a null `branchId` elsewhere means school-wide (BR-TEN-005).

---

## School Calendar

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/schools/{schoolId}/calendar` | TEN-005 | `PERM-SCHOOL-VIEW` | BR-TRIP-011 |
| `PUT` | `/schools/{schoolId}/calendar` | TEN-005 | `PERM-SCHOOL-EDIT` | BR-TRIP-011 |

```json
{ "entries": [ { "date": "2026-08-15", "dayType": "HOLIDAY", "notes": "Independence Day" } ] }
```

Non-operating days suppress trip generation (BR-TRIP-011). `PUT` replaces a date range wholesale — bulk calendar entry is the realistic workflow.

---

## Roles & Permissions

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/permissions` | IAM-006 | `PERM-ROLE-MANAGE` | |
| `GET` | `/roles` | IAM-005 | `PERM-ROLE-MANAGE` | BR-IAM-003 |
| `POST` | `/roles` | IAM-005 | `PERM-ROLE-MANAGE` | BR-IAM-003 |
| `PUT` | `/roles/{id}/permissions` | IAM-006 | `PERM-ROLE-MANAGE` | BR-IAM-002, BR-IAM-004 |
| `DELETE` | `/roles/{id}` | IAM-005 | `PERM-ROLE-MANAGE` | |

`GET /permissions` returns the platform's fixed permission set. **Tenants assign permissions; they cannot invent them** — a role referencing an unknown code is rejected.

Permission changes take effect on the **next request** for every affected user, without re-issuing tokens (BR-IAM-004). This is the property that makes revocation meaningful.

System roles (`is_system_role`) match the templates in the permission matrix and cannot be deleted.

---

## Users

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `POST` | `/users` | — | `PERM-USER-CREATE` | BR-IAM-003 |
| `GET` | `/users` | — | `PERM-USER-VIEW` | BR-IAM-006 |
| `GET` | `/users/{id}` | — | `PERM-USER-VIEW` | |
| `PATCH` | `/users/{id}` | — | `PERM-USER-EDIT` | |
| `POST` | `/users/{id}/deactivate` | IAM-008 | `PERM-USER-DEACTIVATE` | BR-IAM-008 |
| `PUT` | `/users/{id}/roles` | IAM-005 | `PERM-ROLE-MANAGE` | BR-IAM-003 |
| `PUT` | `/users/{id}/scopes` | IAM-007 | `PERM-ROLE-MANAGE` | BR-IAM-006 |
| `GET` | `/users/me` | — | authenticated | BR-IAM-004 |
| `PATCH` | `/users/me` | — | `PERM-PROFILE-SELF-EDIT` | |

### `POST /users/{id}/deactivate`

Revokes **every session immediately** and removes the user from future duty assignments (BR-IAM-008). This is the endpoint called when a driver leaves employment — the delay between "no longer employed" and "no longer has access to children's data" must be zero.

A user must have an email or a phone (`ck_users_identifier`) — guardians commonly have only a phone.

### `PUT /users/{id}/scopes`

```json
{ "scopes": [ { "level": "SCHOOL", "refId": "…" }, { "level": "ROUTE", "refId": "…" } ] }
```

`OWN_CHILDREN`, `TRIP`, and `SELF` are **not settable** — they are derived at request time from guardian links and trip crew ([`MOD-02-identity.md`](../03-database/tables/MOD-02-identity.md)). Attempting to set one returns `400`.

---

## Data Access Log

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/students/{studentId}/access-log` | IAM-010 | `PERM-AUDIT-VIEW` | BR-IAM-012 |

Who has read this child's data, when, and why. Every non-guardian read is recorded (BR-IAM-012) — the control that makes insider misuse detectable rather than merely prohibited.

---

## Platform Operations

| Method | Path | Permission | Rules |
|---|---|---|---|
| `POST` | `/platform/tenant-access` | `PERM-PLATFORM-TENANT-ACCESS` | BR-TEN-004 🔴 |
| `GET` | `/platform/health` | `PERM-PLATFORM-HEALTH-VIEW` | |
| `GET`/`POST` | `/platform/region-profiles` | `PERM-PLATFORM-REGION-MANAGE` | ADR-0007 |

### `POST /platform/tenant-access`

```json
{ "organizationId": "…", "justification": "Support ticket #4821 — parent reports missing notification", "durationMinutes": 30 }
```

The **only** path across the tenant boundary (BR-TEN-004 🔴). `justification` is required — omitting it returns `403 AUTH_JUSTIFICATION_REQUIRED`. An audit record is written **before** access is granted, elevation is time-boxed, and every read during it is logged.

---

## Verification

1. A school cannot be created without a timezone.
2. Removing the last school of an active organization is refused.
3. A school cannot change organization.
4. A role cannot reference a permission code absent from `/permissions`.
5. Removing a permission from a role takes effect on the next request.
6. Deactivating a user revokes all their sessions immediately.
7. Setting a derived scope level returns `400`.
8. Platform tenant access without a justification is refused, and a successful elevation writes an audit record before the first read.
9. Suspending an organization does not stop safety recording on in-progress trips.
