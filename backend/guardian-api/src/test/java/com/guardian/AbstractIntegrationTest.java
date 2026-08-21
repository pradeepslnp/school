package com.guardian;

import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * Base class for integration tests.
 *
 * <p>Real PostgreSQL, real migrations, real row-level security. The application connects as {@code
 * guardian_app}, which is neither the table owner nor holds {@code BYPASSRLS} — connecting as the
 * owner would silently pass every isolation test in this suite while providing no isolation at all.
 */
@SpringBootTest(classes = GuardianApplication.class)
public abstract class AbstractIntegrationTest {

  protected static final UUID ORGANIZATION_A = UUID.randomUUID();
  protected static final UUID ORGANIZATION_B = UUID.randomUUID();
  protected static final TenantId TENANT_A = TenantId.of(ORGANIZATION_A);
  protected static final TenantId TENANT_B = TenantId.of(ORGANIZATION_B);

  /**
   * One PostgreSQL instance shared by every integration test class.
   *
   * <p>Started manually rather than with {@code @Container}, which would create a container per
   * test class. Spring caches an application context by its configuration, so every subclass here
   * shares one context — and therefore one JDBC URL, fixed when that context was first built. A
   * second container would leave later classes pointed at the first container's database, which
   * surfaces as "relation does not exist" long after the real cause.
   *
   * <p>Never stopped: Ryuk removes it when the JVM exits.
   */
  static final PostgreSQLContainer<?> POSTGRES =
      new PostgreSQLContainer<>("postgres:16-alpine")
          .withDatabaseName("guardian")
          .withUsername("guardian_owner")
          .withPassword("test_owner")
          .withInitScript("db/testcontainers-init.sql");

  static {
    POSTGRES.start();
  }

  @DynamicPropertySource
  static void datasourceProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
    registry.add("spring.datasource.username", () -> "guardian_app");
    registry.add("spring.datasource.password", () -> "test_app");
    // spring.flyway.url must be set for flyway.user/password to take effect at all — without
    // it Spring Boot reuses the primary DataSource and migrations run as guardian_app, which
    // has no CREATE privilege. That produced an empty schema and, worse, RLS assertions that
    // passed vacuously because "every table" was zero tables.
    registry.add("spring.flyway.url", POSTGRES::getJdbcUrl);
    registry.add("spring.flyway.user", POSTGRES::getUsername);
    registry.add("spring.flyway.password", POSTGRES::getPassword);
  }

  @Autowired protected JdbcTemplate jdbcTemplate;
  @Autowired protected TransactionTemplate transactionTemplate;

  /** Owner-privileged template for setup and for asserting on schema metadata. */
  protected JdbcTemplate ownerJdbcTemplate() {
    var dataSource = new org.springframework.jdbc.datasource.DriverManagerDataSource();
    dataSource.setUrl(POSTGRES.getJdbcUrl());
    dataSource.setUsername(POSTGRES.getUsername());
    dataSource.setPassword(POSTGRES.getPassword());
    return new JdbcTemplate(dataSource);
  }

  @BeforeEach
  void resetAndSeed() {
    // One container is shared by every test class, so rows written by one test outlive it.
    // Without this reset, a test that inserts a school collides with the next on
    // uq_schools_org_code — and the failure lands on whichever test happens to run second,
    // which makes it look like an isolation defect rather than leftover state.
    //
    // Truncated as owner: the whole point of these tests is that the application role cannot
    // reach across tenants, so it must not be the role that cleans up.
    JdbcTemplate owner = ownerJdbcTemplate();
    owner.execute("TRUNCATE TABLE schools, organizations RESTART IDENTITY CASCADE");

    // Organizations are the tenant table itself, seeded as owner before any context exists.
    insertOrganization(owner, ORGANIZATION_A, "ORG-A");
    insertOrganization(owner, ORGANIZATION_B, "ORG-B");
  }

  @AfterEach
  void clearTenantContext() {
    TenantContext.clear();
  }

  private void insertOrganization(JdbcTemplate owner, UUID id, String code) {
    owner.update(
        """
        INSERT INTO organizations (id, code, name, region_profile_code, status)
        VALUES (?, ?, ?, 'IN', 'ACTIVE')
        ON CONFLICT (id) DO NOTHING
        """,
        id,
        code,
        code);
  }

  /**
   * Runs {@code action} in a transaction with {@code app.tenant_id} bound to the given tenant.
   *
   * <p>{@code SET LOCAL}, never plain {@code SET}: the setting must expire with the transaction. A
   * session-scoped {@code SET} outlives the request and, behind a connection pool, leaks the
   * previous tenant's context into the next borrower — a cross-tenant read with no error and no log
   * entry. {@code RlsSchemaInvariantsIT} tests for exactly that.
   */
  protected <T> T inTenant(TenantId tenantId, Supplier<T> action) {
    return transactionTemplate.execute(
        status -> {
          jdbcTemplate.execute("SET LOCAL app.tenant_id = '" + tenantId.value() + "'");
          return TenantContext.runAs(tenantId, action);
        });
  }

  protected void inTenant(TenantId tenantId, Runnable action) {
    inTenant(
        tenantId,
        () -> {
          action.run();
          return null;
        });
  }

  /** Runs {@code action} in a transaction with no tenant context established. */
  protected <T> T withoutTenantContext(Supplier<T> action) {
    return transactionTemplate.execute(status -> action.get());
  }
}
