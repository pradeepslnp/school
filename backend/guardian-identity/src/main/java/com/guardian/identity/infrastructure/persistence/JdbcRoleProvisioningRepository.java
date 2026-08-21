package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.RoleProvisioningPort;
import com.guardian.identity.domain.RoleId;
import com.guardian.identity.domain.UserId;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Implements {@link RoleProvisioningPort} with plain JDBC against {@code roles} and {@code
 * user_roles} directly, rather than JPA entities — see that port's documentation on why these
 * tables have no domain aggregate of their own here.
 *
 * <p>No {@code SECURITY DEFINER}, no {@code BYPASSRLS}: unlike {@code
 * JdbcOrganizationCodeDirectory} this runs inside the caller's own, already-established tenant
 * context (feature STF-001 provisions a login for a driver the caller is creating in their own
 * tenant, never another one), so ordinary RLS on the current connection is exactly the right
 * protection and needs no bypass.
 *
 * <p>Both statements use Postgres's {@code ON CONFLICT ... DO UPDATE ... RETURNING} idiom rather
 * than {@code DO NOTHING}: a true no-op update still counts as an affected row, so the existing id
 * comes back either way — {@code DO NOTHING} would return nothing at all on the conflict path,
 * which is the common path once a tenant's first driver has already created the role.
 */
@Component
class JdbcRoleProvisioningRepository implements RoleProvisioningPort {

  private final JdbcTemplate jdbcTemplate;

  JdbcRoleProvisioningRepository(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  public RoleId findOrCreateSystemRole(TenantId tenantId, String code, String name) {
    UUID id =
        jdbcTemplate.queryForObject(
            """
            INSERT INTO roles (tenant_id, code, name, is_system_role)
            VALUES (?, ?, ?, true)
            ON CONFLICT (tenant_id, code) DO UPDATE SET code = EXCLUDED.code
            RETURNING id
            """,
            UUID.class,
            tenantId.value(),
            code,
            name);
    return RoleId.of(id);
  }

  @Override
  public void grantIfMissing(TenantId tenantId, UserId userId, RoleId roleId) {
    jdbcTemplate.update(
        """
        INSERT INTO user_roles (tenant_id, user_id, role_id)
        VALUES (?, ?, ?)
        ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING
        """,
        tenantId.value(),
        userId.value(),
        roleId.value());
  }
}
