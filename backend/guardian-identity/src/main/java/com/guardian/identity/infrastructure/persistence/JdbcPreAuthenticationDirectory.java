package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Calls the two {@code SECURITY DEFINER} functions from V3__identity.sql.
 *
 * <p>Plain JDBC rather than JPA, deliberately. These are function calls returning a projection, not
 * entity reads — routing them through Hibernate would put {@code users} and {@code sessions}
 * entities in a persistence context that has no tenant, which is exactly the confusion this port
 * exists to avoid. The queries below cannot accidentally become a general-purpose cross-tenant
 * read, because a function is all they can reach.
 *
 * <p>{@link Propagation#NOT_SUPPORTED} suspends any surrounding transaction. That matters: these
 * run <em>before</em> tenant context exists, and joining a transaction whose connection had already
 * been given a different tenant's {@code SET LOCAL} would mean the function ran under it.
 * Suspended, each call gets its own connection with no tenant set — and since the functions run as
 * the owner, that is exactly right.
 */
@Component
class JdbcPreAuthenticationDirectory implements PreAuthenticationDirectory {

  private final JdbcTemplate jdbcTemplate;

  JdbcPreAuthenticationDirectory(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  @Transactional(propagation = Propagation.NOT_SUPPORTED)
  public List<PhoneMatch> findByPhone(PhoneNumber phone) {
    return jdbcTemplate.query(
        "SELECT user_id, tenant_id, status FROM auth_resolve_phone(?)",
        (rs, rowNum) ->
            new PhoneMatch(
                UserId.of(rs.getObject("user_id", UUID.class)),
                TenantId.of(rs.getObject("tenant_id", UUID.class)),
                UserStatus.fromStored(rs.getString("status"))),
        phone.value());
  }

  @Override
  @Transactional(propagation = Propagation.NOT_SUPPORTED)
  public List<EmailMatch> findByEmail(String email) {
    return jdbcTemplate.query(
        "SELECT user_id, tenant_id, status FROM auth_resolve_email(?)",
        (rs, rowNum) ->
            new EmailMatch(
                UserId.of(rs.getObject("user_id", UUID.class)),
                TenantId.of(rs.getObject("tenant_id", UUID.class)),
                UserStatus.fromStored(rs.getString("status"))),
        email);
  }

  @Override
  @Transactional(propagation = Propagation.NOT_SUPPORTED)
  public Optional<SessionLocation> findSessionByRefreshTokenHash(String refreshTokenHash) {
    List<SessionLocation> found =
        jdbcTemplate.query(
            "SELECT session_id, tenant_id FROM auth_resolve_refresh_token(?)",
            (rs, rowNum) ->
                new SessionLocation(
                    SessionId.of(rs.getObject("session_id", UUID.class)),
                    TenantId.of(rs.getObject("tenant_id", UUID.class))),
            refreshTokenHash);

    // refresh_token_hash is UNIQUE, so more than one row is impossible rather than merely
    // unexpected. Taking the first would hide a schema change that removed the constraint.
    return found.isEmpty() ? Optional.empty() : Optional.of(found.get(0));
  }
}
