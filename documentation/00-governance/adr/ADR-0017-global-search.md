# ADR-0017: Console global search as a read-only composition module

**Status:** Accepted — its rejection of cross-organization search for a `SUPER_ADMIN` is superseded by [ADR-0018](ADR-0018-platform-wide-search.md)
**Date:** 2026-09-14
**Affects:** [`MODULE_MAP.md`](../../01-product-discovery/MODULE_MAP.md), [`PERMISSION_MATRIX.md`](../../01-product-discovery/PERMISSION_MATRIX.md), [`FEATURE_INVENTORY.md`](../../01-product-discovery/FEATURE_INVENTORY.md) (SRC-001), [`SEARCH_API.md`](../../04-api/SEARCH_API.md), [`ADMIN_WEB.md`](../../05-ui/ADMIN_WEB.md) §Global Search, `com.guardian.search`, `CallerAccessArgumentResolver`

## Context

Operators need to find a record by what they know about it — a child's name, a parent's phone number, an admission or registration number, a driver's employee code — from one field, and to see what kind of record each match is and where it belongs, without first choosing the screen it lives on.

Six forces apply at once:

1. **It crosses modules.** The records live in MOD-01, 02, 03, 04, 05, 06 and 07. Cross-module rule 1 forbids one module reading another's tables, and the cycle rule forbids any of them depending upward on the others.
2. **Visibility differs per kind of record.** Each kind has its own view permission in the matrix — a `PRINCIPAL` may view students but not transport staff — and school scope narrows every one of them (BR-IAM-006). The existing list endpoints accept any `schoolId` in the caller's tenant and do not enforce school scope server-side, so they are not a model to copy.
3. **Showing a child is reading their data.** BR-IAM-012 🔴 requires one data-access record per student shown, and as-you-type search multiplies the number of reads.
4. **Tenants stay isolated.** A `SUPER_ADMIN` reaches another organization only through the audited, one-organization-per-request elevation (ADR-0016). Their own permissions and scope live in their home tenant, not the one a request acts in.
5. **No server-built display text** (BR-CFG-005).
6. **There is no search infrastructure** — no search index and no trigram indexes — and a tenant's searchable rows number in the thousands.

## Decision

**Introduce MOD-19 `com.guardian.search`, a read-only module that owns no tables**, serving `GET /api/v1/search?q=`.

- **Composition, not ownership.** One JDBC projection behind a `SearchReadModel` port, running under the tenant-aware DataSource so row-level security applies to every statement — the bounded exception ADR-0010 accepted for MOD-18, applied to a staff-facing read. MOD-19 depends on MOD-01 only to reuse `ListOrganizationsUseCase`, the single gated path to a platform operator's cross-tenant organization list, rather than becoming a second caller of its unfiltered database function.
- **Gate on the surface, decide per kind.** The endpoint requires a new permission, `PERM-SEARCH-QUERY`, held by the five console roles. It grants no data: each kind is searched only when the caller holds that kind's own view permission — the same one its screen and endpoint require — so search never shows a record the caller could not already open.
- **Scope in the query.** Every school-bound kind carries `(? OR school_id = ANY(?))`, bound from the caller's current `user_scopes` row: `PLATFORM`/`ORG` reaches the acting organization, `SCHOOL` its school, anything else nothing. Scope is never applied as a post-filter.
- **Caller access resolved once, in the home tenant.** `CallerAccess` (guardian-common) carries the resolved permissions and scope to the controller. Its resolver reuses the permission set `PermissionEnforcementInterceptor` already resolved for the request, and reads scope in the caller's home tenant, as the interceptor does for permissions.
- **Bounded reads.** The query must be 3–100 characters after trimming; the server refuses anything else. At most 5 results per kind are returned, with a `hasMore` flag instead of paging.
- **Every student shown is recorded.** Each student result, and the linked child shown beside a guardian, writes a `LIST` data-access record (purpose `GLOBAL_SEARCH`) in the same transaction. Rows fetched only to compute `hasMore` are not shown and not recorded.
- **Structured results.** Each result carries its type, the field that matched, and type-specific identifiers; the console composes the text.
- **Plain `LIKE` over tenant-scoped rows.** No index is added now.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Client-side search over the existing list endpoints | Needs a `schoolId` per call, downloads whole registers — recording a data access for every child in them — and cannot search across schools. |
| A search endpoint per module, combined in the console | Several round trips per keystroke, and the permission, scope, and access-recording logic duplicated in every module. |
| OpenSearch / Elasticsearch | New infrastructure, plus a copy of child PII held outside row-level security. Premature at a few thousand rows per tenant. |
| `pg_trgm` or full-text indexes now | No measured need yet; adds migrations and index maintenance to every searched table. Named below as the first step when the trigger is met. |
| `@SelfServiceEndpoint` with no permission | That annotation is reserved for acting on one's own identity. Search reads other people's records, so it needs an explicit matrix permission. |
| Cross-organization search for a `SUPER_ADMIN` | A new cross-tenant read path and an amendment to BR-TEN-004 🔴. One organization at a time, through ADR-0016, meets the need. |

## Consequences

**Positive**
- One place enforces per-kind permission, school scope, and child-data access recording for search.
- `CallerAccess` is reusable: it is the missing building block for enforcing BR-IAM-006 on the existing list endpoints.
- Reversible behind the port.

**Negative / accepted cost**
- A third place knows other modules' table shapes (after MOD-15 and MOD-18). A column rename can break the projection; it is one file, and the live verification exercises it against the real schema.
- As-you-type search writes access records per request that shows students — up to 5 students plus 5 linked children per request after a 300 ms typing pause.
- A platform operator's searches each carry the elevation header, so each writes a `PLATFORM_ORG_ELEVATION` audit record — the deliberate noise ADR-0016 accepts.
- **No rate limiting.** API_STANDARDS §Rate Limiting requires it, but the platform has no rate-limiting infrastructure for any endpoint yet. The minimum length, the per-kind cap, and the console's typing pause bound load until it exists.
- **No tenant-isolation integration test yet.** TEST_STRATEGY expects one per module; the current phase has deferred writing new tests, and this module was verified live instead. Recorded as outstanding.

## Reversal Cost

**Low.** MOD-19 owns no tables and no writes of its own apart from access records, so removing it deletes code. The trigger to change the query layer is either a search p95 above 300 ms, or any searched table exceeding roughly 50,000 rows in one tenant. The first response is trigram indexes on the matched columns; a search index would be a second `SearchReadModel` adapter, with nothing above the port changing.

## Verification

1. `EndpointPermissionTest` — the endpoint declares `PERM-SEARCH-QUERY`, which exists in the matrix.
2. `LayerDependencyTest.modules_are_free_of_cycles` — MOD-19 introduces no cycle.
3. Per role, a search returns only kinds that role may view, and only within its school scope. Verified live against the demo data for SA, OA, SCH, PRIN, and TM; an integration test is outstanding (see Consequences).
4. A query shorter than 3 characters returns `400 VALIDATION_VALUE_OUT_OF_RANGE`.
5. Each student in a response has a `data_access_records` row with purpose `GLOBAL_SEARCH`.
