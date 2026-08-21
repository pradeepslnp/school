package com.guardian;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.BusinessRule;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Schema-level invariants that keep tenant isolation true as the schema grows.
 *
 * <p>These are the guards described in guardian-docs/03-database/RLS_POLICIES.md. Most of them
 * cannot be checked by static analysis — they are properties of the live database — and each of
 * them is a mistake that produces <strong>no error at all</strong> when made. A table without a
 * policy simply returns every tenant's rows, and every other test still passes.
 *
 * <p>They run against the live schema after every migration, in CI and again post-deployment.
 */
class RlsSchemaInvariantsIT extends AbstractIntegrationTest {

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("every table with a tenant_id column has RLS enabled AND forced")
  void everyTenantScopedTableHasForcedRls() {
    JdbcTemplate owner = ownerJdbcTemplate();

    List<String> offenders =
        owner.queryForList(
            """
            SELECT c.relname
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public'
              AND c.relkind IN ('r', 'p')
              AND EXISTS (
                  SELECT 1 FROM information_schema.columns col
                  WHERE col.table_schema = 'public'
                    AND col.table_name = c.relname
                    AND col.column_name = 'tenant_id')
              AND NOT (c.relrowsecurity AND c.relforcerowsecurity)
            """,
            String.class);

    // FORCE matters as much as ENABLE: without it the table owner bypasses the policy,
    // so any process connecting as owner reads every tenant.
    assertThat(offenders)
        .as("tables with tenant_id but without ENABLE + FORCE row level security")
        .isEmpty();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("every RLS policy declares both USING and WITH CHECK")
  void everyPolicyHasUsingAndWithCheck() {
    JdbcTemplate owner = ownerJdbcTemplate();

    List<String> offenders =
        owner.queryForList(
            """
            SELECT tablename || '.' || policyname
            FROM pg_policies
            WHERE schemaname = 'public'
              AND (qual IS NULL OR with_check IS NULL)
            """,
            String.class);

    // USING alone protects reads but permits WRITING a row bearing another tenant's id.
    // A policy with only USING is half a control.
    assertThat(offenders).as("policies missing USING or WITH CHECK").isEmpty();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("the application role cannot bypass row-level security")
  void applicationRoleCannotBypassRls() {
    JdbcTemplate owner = ownerJdbcTemplate();

    Boolean bypassRls =
        owner.queryForObject(
            "SELECT rolbypassrls FROM pg_roles WHERE rolname = 'guardian_app'", Boolean.class);
    Boolean superuser =
        owner.queryForObject(
            "SELECT rolsuper FROM pg_roles WHERE rolname = 'guardian_app'", Boolean.class);

    // This single misconfiguration removes all isolation while breaking nothing visible.
    assertThat(bypassRls).as("guardian_app must not have BYPASSRLS").isFalse();
    assertThat(superuser).as("guardian_app must not be a superuser").isFalse();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("the one role that bypasses RLS cannot log in and owns only the pre-auth lookups")
  void preAuthenticationRoleIsContained() {
    JdbcTemplate owner = ownerJdbcTemplate();

    Boolean canLogin =
        owner.queryForObject(
            "SELECT rolcanlogin FROM pg_roles WHERE rolname = 'guardian_preauth'", Boolean.class);

    // guardian_preauth exists to let the two pre-authentication lookups see across tenants
    // before a tenant is known (V3__identity.sql). It genuinely bypasses row-level security,
    // so the only thing keeping that contained is that nothing can connect as it and nothing
    // else runs with its privileges. NOLOGIN is therefore load-bearing, not hygiene.
    assertThat(canLogin).as("guardian_preauth must not be able to open a connection").isFalse();

    List<String> ownedTables =
        owner.queryForList(
            """
            SELECT tablename FROM pg_tables
            WHERE schemaname = 'public' AND tableowner = 'guardian_preauth'
            """,
            String.class);
    assertThat(ownedTables).as("guardian_preauth must own no tables").isEmpty();

    List<String> ownedFunctions =
        owner.queryForList(
            """
            SELECT p.proname
            FROM pg_proc p
            JOIN pg_roles r ON r.oid = p.proowner
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public' AND r.rolname = 'guardian_preauth'
            ORDER BY p.proname
            """,
            String.class);

    // Every function this role owns runs with RLS bypassed. Listing them exactly means a new
    // one cannot be added quietly — each addition is a decision that has to be made here too.
    //
    // Each entry earns its place by returning identifiers or a boolean and nothing else, so a
    // defect in one cannot become a data leak: the reads that follow run under ordinary RLS with
    // the tenant the lookup returned.
    //
    //   auth_resolve_phone          guardian sign-in — whose number is this? (V3)
    //   auth_resolve_refresh_token  which session holds this token, and whose tenant? (V3)
    //   auth_resolve_email          staff sign-in, the same shape as phone (V10)
    //   org_code_exists             returns a bare boolean: is this organization code taken? (V11)
    //
    // The last two were added by their migrations without being recorded here, which is what this
    // assertion exists to catch.
    assertThat(ownedFunctions)
        .as("only the pre-authentication lookups may run with RLS bypassed")
        .containsExactly(
            "auth_resolve_email",
            "auth_resolve_phone",
            "auth_resolve_refresh_token",
            "org_code_exists");
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("the application role does not own any table")
  void applicationRoleOwnsNoTables() {
    JdbcTemplate owner = ownerJdbcTemplate();

    List<String> owned =
        owner.queryForList(
            """
            SELECT tablename FROM pg_tables
            WHERE schemaname = 'public' AND tableowner = 'guardian_app'
            """,
            String.class);

    assertThat(owned).as("guardian_app must not own tables — FORCE would not apply").isEmpty();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("with no tenant context, reads return nothing rather than everything")
  void unsetContextReturnsNoRows() {
    inTenant(
        TENANT_A, () -> jdbcTemplate.update(insertSchoolSql(), schoolArgs(ORGANIZATION_A, "A-1")));

    Integer visible =
        withoutTenantContext(
            () -> jdbcTemplate.queryForObject("SELECT COUNT(*) FROM schools", Integer.class));

    // current_setting('app.tenant_id', true) yields NULL when unset, and `tenant_id = NULL`
    // is never true. The failure mode is "sees nothing", never "sees everything".
    assertThat(visible).isZero();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("a write bearing another tenant's id is rejected by WITH CHECK")
  void crossTenantWriteIsRejected() {
    assertThatThrownBy(
            () ->
                inTenant(
                    TENANT_A,
                    () ->
                        jdbcTemplate.update(
                            insertSchoolSql(),
                            schoolArgsForTenant(TENANT_B.value(), ORGANIZATION_B, "X-1"))))
        // PostgreSQL reports an RLS WITH CHECK violation as SQLState 42501
        // (insufficient_privilege), which Spring translates to BadSqlGrammarException — a
        // misleading type whose own message carries only the SQL. The evidence that the policy
        // fired is in the root cause, so that is what this asserts on. Checking the wrapper's
        // message would pass for any malformed statement and prove nothing about isolation.
        .rootCause()
        .hasMessageContaining("row-level security");
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("tenant context does not leak between transactions on a pooled connection")
  void tenantContextDoesNotLeakAcrossTransactions() {
    inTenant(
        TENANT_A, () -> jdbcTemplate.update(insertSchoolSql(), schoolArgs(ORGANIZATION_A, "A-2")));

    // Second transaction, same pool, different tenant. If SET (session-scoped) were used
    // instead of SET LOCAL, tenant A's context could still be in force here and this would
    // return a non-zero count — a silent cross-tenant read.
    Integer seenByB =
        inTenant(
            TENANT_B,
            () ->
                jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM schools WHERE code = 'A-2'", Integer.class));

    assertThat(seenByB).isZero();
  }

  @Test
  @BusinessRule("BR-AUD-001")
  @DisplayName("audit records reject UPDATE and DELETE")
  void auditRecordsAreAppendOnly() {
    inTenant(
        TENANT_A,
        () ->
            jdbcTemplate.update(
                """
                INSERT INTO audit_records
                    (id, tenant_id, actor_type, action, subject_type, subject_id, source)
                VALUES (?, ?, 'SYSTEM', 'TEST_ACTION', 'Test', ?, 'JOB')
                """,
                UUID.randomUUID(),
                TENANT_A.value(),
                UUID.randomUUID()));

    // Two independent controls: the runtime role has no UPDATE/DELETE grant, and a trigger
    // rejects the operation regardless of grants.
    assertThatThrownBy(
            () ->
                inTenant(
                    TENANT_A,
                    () -> jdbcTemplate.update("UPDATE audit_records SET action = 'TAMPERED'")))
        .isNotNull();

    assertThatThrownBy(
            () -> inTenant(TENANT_A, () -> jdbcTemplate.update("DELETE FROM audit_records")))
        .isNotNull();
  }

  private static String insertSchoolSql() {
    return """
        INSERT INTO schools
            (id, tenant_id, organization_id, code, name, timezone,
             latitude, longitude, geofence_radius_m, status)
        VALUES (?, ?, ?, ?, ?, 'Asia/Kolkata', 28.612900, 77.229000, 150, 'ACTIVE')
        """;
  }

  private static Object[] schoolArgs(UUID organizationId, String code) {
    return schoolArgsForTenant(organizationId, organizationId, code);
  }

  private static Object[] schoolArgsForTenant(UUID tenantId, UUID organizationId, String code) {
    return new Object[] {UUID.randomUUID(), tenantId, organizationId, code, "Campus " + code};
  }
}
