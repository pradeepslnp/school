package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.UserScopeRepository;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserScope;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Implements {@link UserScopeRepository} with plain JDBC against {@code user_scopes} directly,
 * matching {@link JdbcRoleProvisioningRepository} — see that class's documentation for why these
 * access-control tables are read and written without a JPA entity.
 */
@Component
class JdbcUserScopeRepository implements UserScopeRepository {

  private final JdbcTemplate jdbcTemplate;

  JdbcUserScopeRepository(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  public List<UserScope> findByUser(UserId userId) {
    return jdbcTemplate.query(
        "SELECT scope_level, scope_ref_id FROM user_scopes WHERE user_id = ?",
        (rs, rowNum) -> {
          UUID refId = (UUID) rs.getObject("scope_ref_id");
          return new UserScope(UserScope.Level.fromStored(rs.getString("scope_level")), refId);
        },
        userId.value());
  }

  @Override
  public void add(TenantId tenantId, UserId userId, UserScope scope) {
    jdbcTemplate.update(
        """
        INSERT INTO user_scopes (tenant_id, user_id, scope_level, scope_ref_id)
        VALUES (?, ?, ?, ?)
        """,
        tenantId.value(),
        userId.value(),
        scope.level().name(),
        scope.refId());
  }
}
