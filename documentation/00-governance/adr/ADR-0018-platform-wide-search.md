# ADR-0018: Platform-wide search for platform operators

**Status:** Accepted
**Date:** 2026-09-14
**Supersedes:** ADR-0017's rejection of cross-organization search for a `SUPER_ADMIN`. The rest of ADR-0017 stands.
**Affects:** [`BUSINESS_RULES.md`](../../01-product-discovery/BUSINESS_RULES.md) BR-TEN-004, [`SEARCH_API.md`](../../04-api/SEARCH_API.md), [`ADMIN_WEB.md`](../../05-ui/ADMIN_WEB.md) §Global Search, [`INDEXING_AND_PARTITIONING.md`](../../03-database/INDEXING_AND_PARTITIONING.md), `V19__platform_search.sql`, `com.guardian.search`, `AccessScope`

## Context

ADR-0017 built the console's global search inside one organization at a time. A platform operator reached another organization's records only by choosing it first in a picker beside the search field, which sent the audited elevation header (ADR-0016) with each search.

The product owner rejected that picker: a platform operator's search must be universal — one query, matches from every organization. Two facts make that impossible on the existing paths:

1. **Row-level security answers for one tenant.** Every policy compares `tenant_id` to `app.tenant_id`, which a request sets to exactly one organization. ADR-0016's elevation widens *who* may set it, never *how many* organizations one statement sees.
2. **Looping over organizations does not scale.** Running the tenant-scoped search once per organization per keystroke is thousands of queries at the platform's target scale.

BR-TEN-004 🔴 permits crossing organizations only "through an explicitly permissioned platform-operations path, which is always audited", and named ADR-0016 as that path. ADR-0016 itself rejected `SECURITY DEFINER` read functions per table — for a requirement to *edit* inside an organization, where a dozen bypass functions would be a dozen places for policy to drift.

## Decision

**Add a second platform-operations path, for search only.** `BR-TEN-004` is amended to name it.

- **Read-only functions in the schema.** `V19__platform_search.sql` defines seven `SECURITY DEFINER` functions — `platform_search_students`, `…_guardians`, `…_staff`, `…_vehicles`, `…_routes`, `…_schools`, `…_administrative_users` — owned by `guardian_platform_ops` (`NOLOGIN`, `BYPASSRLS`), executable by `guardian_app`, revoked from `PUBLIC`. This follows `list_organizations()` (V12). Each returns a fixed projection plus the organization of each row, refuses a pattern shorter than 3 characters besides wildcards, and caps its rows at 26 whatever the caller passes. `guardian_app` still holds no `BYPASSRLS` and owns no tables.
- **Permissioned by scope, re-checked at the use case.** The path is taken only when the caller's current scope is `PLATFORM` — the matrix's own definition of that scope is "across organizations; platform operators only; always audited" — and only for a `SUPER_ADMIN`. A `PLATFORM` scope row on any other role resolves to no scope at all. `RunPlatformSearchUseCase` refuses any other caller itself rather than trusting the controller's routing. Each kind of record still requires its own view permission.
- **Audited in the organization that was crossed.** Every organization whose records appear in a response receives a `PLATFORM_CROSS_ORG_SEARCH` audit record in its own trail (BR-AUD-005). The query text is not recorded — it is often a child's name (BR-AUD-006). Every student shown receives a `LIST` data-access record, purpose `GLOBAL_SEARCH`, in that student's organization (BR-IAM-012). All records are written before results are returned; a failed write fails the request.
- **Trigram indexes** (`pg_trgm` GIN) on exactly the expressions both search paths filter on, so a substring search across every tenant does not scan every row.
- **Everyone else is unchanged.** `ORG_ADMIN`, `SCHOOL_ADMIN`, `PRINCIPAL` and `TRANSPORT_MANAGER` keep ADR-0017's tenant-scoped search, enforced by row-level security.
- **The console** drops the organization picker. Platform results name their organization; opening one enters that organization through the ordinary elevation (ADR-0016).

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Keep the picker (ADR-0017) | Rejected by the product owner: search must be universal. |
| Run the tenant-scoped search once per organization | One query per organization per keystroke — thousands at target scale. |
| Grant `guardian_app` membership in a `BYPASSRLS` role and `SET ROLE` around search | Any application code could then switch roles and read anything. Functions confine the bypass to fixed, reviewable projections. |
| Pass a tenant list to row-level security (`app.tenant_ids`) | Changes every policy on every table to serve one feature — a far larger surface than seven read functions. |
| A search index (OpenSearch) | New infrastructure, and a copy of every organization's child PII outside row-level security. |
| Gate on `PERM-PLATFORM-TENANT-ACCESS` | That permission is documented as justification-bearing and time-boxed (`POST /platform/tenant-access`); search has neither. The `PLATFORM` scope is the matrix's existing statement of "across organizations". |

## Consequences

**Positive**
- A platform operator finds any record in one query, without knowing which organization holds it.
- The bypass is a fixed set of schema objects, owned by a role no one logs in as, and visible in one migration.
- The trigram indexes speed up the tenant-scoped search too.

**Negative / accepted cost**
- **Seven functions duplicate the tenant-scoped SQL.** A column change in a searched table must be made in both `JdbcSearchReadModel` and `V19__platform_search.sql`. Both map rows through one shared mapper (`SearchRows`), so a shape mismatch fails loudly.
- **Audit volume.** Every platform search that shows records writes one audit record per organization shown — the deliberate noise ADR-0016 already accepts for crossing boundaries.
- **Write cost of 18 GIN indexes** on inserts, most visible in bulk student import.
- **`pg_trgm` must be available.** It is a trusted extension on PostgreSQL 13+ and on managed PostgreSQL; a database without it fails V19.
- Rate limiting and a tenant-isolation integration test remain outstanding, as ADR-0017 records.

## Reversal Cost

**Low to moderate.** Dropping the functions and returning to per-organization search is a migration and a console change. Moving search to an index would replace both read models behind their ports. Reconsider if the functions' plans stop using the trigram indexes, or when a second feature asks for cross-organization reads — that should extend a single designed path, not add an eighth function.

## Verification

1. A `SUPER_ADMIN` search returns records from more than one organization, each naming its organization.
2. Each organization shown has a `PLATFORM_CROSS_ORG_SEARCH` audit record; each student shown has a `GLOBAL_SEARCH` data-access record in its own organization.
3. An `ORG_ADMIN` search still returns only its own organization's records.
4. Calling a `platform_search_*` function with a pattern shorter than 3 characters returns no rows.
5. `guardian_app` still lacks `BYPASSRLS` and cannot select from the searched tables without row-level security.
