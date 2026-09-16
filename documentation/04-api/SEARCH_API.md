# SEARCH API

**Document tier:** 4 — API
**Implements:** ADR-0017, ADR-0018 · **Feature:** SRC-001 · **Module:** MOD-19 · **Rules:** BR-IAM-002, BR-IAM-006, BR-IAM-012, BR-TEN-004, BR-AUD-005

---

## `GET /search?q=` — Global search

**Permission:** `PERM-SEARCH-QUERY` — held by `SUPER_ADMIN`, `ORG_ADMIN`, `SCHOOL_ADMIN`, `PRINCIPAL`, `TRANSPORT_MANAGER`.

| Parameter | Where | Rules |
|---|---|---|
| `q` | query | Required. 3–100 characters after trimming. |

**`200`**
```json
{
  "data": {
    "query": "9990",
    "groups": [
      {
        "type": "STAFF",
        "hasMore": false,
        "results": [
          {
            "type": "STAFF",
            "id": "…",
            "title": "Suresh Kumar",
            "matchedField": "PHONE",
            "matchedValue": "9990000001",
            "kind": "DRIVER",
            "code": "EMP-104",
            "status": "ACTIVE",
            "schoolId": "…",
            "schoolName": "Greenwood Main Campus",
            "relatedStudentId": null,
            "relatedStudentName": null,
            "organizationId": null,
            "organizationName": null
          }
        ]
      }
    ]
  }
}
```

Groups appear in the order below. A kind the caller may not see, or with no matches, is **absent** rather than empty.

### What is searched, and for whom

Holding `PERM-SEARCH-QUERY` returns nothing by itself. A kind is searched only when the caller also holds its own view permission, and only within their scope (BR-IAM-006).

| `type` | Matched on | Requires | Scope |
|---|---|---|---|
| `STUDENT` | name, admission number | `PERM-STUDENT-VIEW` | school |
| `GUARDIAN` | name, phone, email | `PERM-STUDENT-VIEW` | actively linked to a student in scope |
| `STAFF` | name, phone, employee code | `PERM-STAFF-MANAGE` | school |
| `VEHICLE` | display name, registration number | `PERM-VEHICLE-VIEW` | school |
| `ROUTE` | name, code | `PERM-ROUTE-VIEW` | school |
| `USER` | name, email, phone | `PERM-USER-VIEW` | organization; a school-scoped caller sees only accounts scoped to their school |
| `SCHOOL` | name, code | `PERM-SCHOOL-VIEW` | school |
| `ORGANIZATION` | name, code | `PERM-ORG-VIEW` | `SUPER_ADMIN`: every organization; anyone else: their own |

Scope comes from the caller's current `user_scopes` row, read server-side: `PLATFORM` (a `SUPER_ADMIN`) reaches **every organization** — see [Across organizations](#across-organizations-platform-operators); `ORG` reaches every school in the organization the request acts in; `SCHOOL` reaches that school; no scope reaches no school. `USER` covers administrative accounts only (`ORG_ADMIN`, `SCHOOL_ADMIN`, `PRINCIPAL`, `TRANSPORT_MANAGER`) — guardians and transport staff are found as themselves.

### Result fields

`title` is the record's name. `matchedField` is one of `NAME`, `ADMISSION_NO`, `PHONE`, `EMAIL`, `EMPLOYEE_CODE`, `REGISTRATION_NO`, `CODE`, and `matchedValue` is the value that matched. The optional fields depend on `type`:

| `type` | `kind` | `code` | `status` | `schoolId` / `schoolName` | `relatedStudent…` |
|---|---|---|---|---|---|
| `STUDENT` | — | admission number | enrolment status | their school | — |
| `GUARDIAN` | — | — | `ACTIVE` / `INACTIVE` | the child's school | the linked child shown (primary link first) |
| `STAFF` | `DRIVER` / `ATTENDANT` | employee code | `ACTIVE` / `INACTIVE` | their school | — |
| `VEHICLE` | vehicle type | registration number | vehicle status | its school | — |
| `ROUTE` | — | route code | — | its school | — |
| `USER` | role code | — | account status | their school, when school-scoped | — |
| `SCHOOL` | — | school code | school status | the school itself | — |
| `ORGANIZATION` | region profile | organization code | organization status | — | — |

`organizationId` and `organizationName` are set only on a platform operator's search, on every result except `ORGANIZATION`, naming the organization the record belongs to.

The response carries no display text (BR-CFG-005). The console composes, for example, "9990000001 — Driver · Suresh Kumar · Greenwood Main Campus".

### Matching

- Names, codes, and email match as a case-insensitive substring.
- A query holding 3 or more digits also matches phone numbers by their digits, so `80506 02046` finds `8050602046`.
- Registration numbers also match on letters and digits only, so `ka01ab` finds `KA-01-AB-1234`.
- Within a kind, names starting with the query rank first, then alphabetically. At most **5** results per kind; `hasMore` is `true` when more matched. The console asks the operator to keep typing rather than paging.

### Across organizations (platform operators)

A caller whose current scope is `PLATFORM` — a `SUPER_ADMIN` — searches **every organization at once** (ADR-0018). No header or parameter is needed or accepted to choose one. The same per-kind view permissions apply; school scope does not narrow.

The cross-organization read runs through read-only `SECURITY DEFINER` functions (`V19__platform_search.sql`) rather than row-level security, so it is audited where it lands: **every organization whose records appear in the response receives a `PLATFORM_CROSS_ORG_SEARCH` audit record** in its own trail (BR-TEN-004, BR-AUD-005). The query text is not recorded (BR-AUD-006). Organizations that match only by name or code are the organizations list and are not audited as crossings.

### Data-access recording (BR-IAM-012 🔴)

Every student in a response — each `STUDENT` result and each guardian's related child — is recorded as one `LIST` data-access record with purpose `GLOBAL_SEARCH`, and `record_count` set to the number of distinct students in that response. On a platform operator's search each record is written in the student's own organization. Every record is written before results are returned, so a search whose records cannot be stored returns an error instead of results. Other kinds record nothing.

**Errors:** `VALIDATION_VALUE_OUT_OF_RANGE` (400, `businessRule` `BR-IAM-012`) when `q` is missing, shorter than 3, or longer than 100 characters · `AUTH_PERMISSION_DENIED` (403) without `PERM-SEARCH-QUERY` · `ORG_SUSPENDED` (403) when the caller's organization is suspended.

### Not yet built

- **Rate limiting.** Required by [`API_STANDARDS.md`](API_STANDARDS.md) §Rate Limiting; the platform has no rate-limiting infrastructure yet. Until it does, the length bounds, the per-kind cap, and the console's typing pause bound the load.

---

## Verification

1. Each console role receives only the kinds its view permissions allow, and only within its school scope.
2. A `SCHOOL_ADMIN` never receives a record from another school in the same organization.
3. A `SUPER_ADMIN` receives records from every organization, each naming its organization, and each organization shown has a `PLATFORM_CROSS_ORG_SEARCH` audit record.
4. A two-character query returns `400`.
5. Every student in a response has a `GLOBAL_SEARCH` data-access record.
6. `GET /search` without `PERM-SEARCH-QUERY` returns `403`.
