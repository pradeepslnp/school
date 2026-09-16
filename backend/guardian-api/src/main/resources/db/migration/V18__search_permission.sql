-- V18 — Global search permission (MOD-19, feature SRC-001, ADR-0017)
--
-- See docs/01-product-discovery/PERMISSION_MATRIX.md §Search and docs/04-api/SEARCH_API.md.
--
-- PERM-SEARCH-QUERY opens the admin console's global search (GET /search). It gates the surface,
-- never the data: every kind of result is still decided by the caller's own view permission and
-- school scope, inside the search projection (ADR-0017). System roles resolve it from
-- SystemRolePermissions in code; this row keeps the reference table the complete permission set
-- that custom roles are built from (V14).
--
-- No table and no row-level security change: MOD-19 owns no tables.
INSERT INTO permissions (code, area, description_key) VALUES
    ('PERM-SEARCH-QUERY', 'SEARCH', 'permission.search_query');
