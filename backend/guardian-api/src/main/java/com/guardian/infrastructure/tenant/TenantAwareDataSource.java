package com.guardian.infrastructure.tenant;

import com.guardian.common.tenant.TenantContext;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import javax.sql.DataSource;
import org.springframework.jdbc.datasource.DelegatingDataSource;

/**
 * Applies the tenant's row-level-security context to every connection handed to the application.
 *
 * <p>This is the single point where {@link TenantContext} meets PostgreSQL. Getting it wrong is the
 * one implementation risk ADR-0001 calls out by name, so the details matter:
 *
 * <ul>
 *   <li><strong>{@code SET LOCAL}, never {@code SET}.</strong> {@code SET LOCAL} is scoped to the
 *       transaction and expires on commit or rollback. Plain {@code SET} persists for the session —
 *       and a pooled session outlives the request, so the next borrower of that connection would
 *       inherit the previous tenant's context. That is a cross-tenant read with no error, no log
 *       entry, and no failing test unless one is written for it specifically.
 *   <li><strong>The value is a UUID, validated by {@code TenantId}.</strong> It cannot carry SQL,
 *       which is why the literal below is safe. A parameterised statement is not available for
 *       {@code SET LOCAL}.
 *   <li><strong>No context is not an error here.</strong> With {@code app.tenant_id} unset, the RLS
 *       predicate compares against NULL and yields zero rows. Unauthenticated and background paths
 *       legitimately reach the database with no tenant, and they must see nothing rather than
 *       everything.
 * </ul>
 *
 * @see guardian-docs/03-database/RLS_POLICIES.md
 */
public class TenantAwareDataSource extends DelegatingDataSource {

  public TenantAwareDataSource(DataSource targetDataSource) {
    super(targetDataSource);
  }

  @Override
  public Connection getConnection() throws SQLException {
    return applyTenantContext(super.getConnection());
  }

  @Override
  public Connection getConnection(String username, String password) throws SQLException {
    return applyTenantContext(super.getConnection(username, password));
  }

  private Connection applyTenantContext(Connection connection) throws SQLException {
    TenantContext.current()
        .ifPresent(
            tenantId -> {
              try (Statement statement = connection.createStatement()) {
                statement.execute("SET LOCAL app.tenant_id = '" + tenantId.value() + "'");
              } catch (SQLException e) {
                throw new IllegalStateException("Could not establish tenant context", e);
              }
            });
    return connection;
  }
}
