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
    // Newest first. user_scopes is append-only (V15 grants no DELETE) — a role change adds a
    // superseding row rather than editing one — so the most recently inserted row is the scope
    // in force, and every reader that takes element 0 (UserResponse, SessionFactory, the Users
    // list) is reading the current scope. Older rows remain as the trail of where this account
    // has been scoped.
    return jdbcTemplate.query(
        "SELECT scope_level, scope_ref_id FROM user_scopes WHERE user_id = ? ORDER BY created_at DESC",
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
