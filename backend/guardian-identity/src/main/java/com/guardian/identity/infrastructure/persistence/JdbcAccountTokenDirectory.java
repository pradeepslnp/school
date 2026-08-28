package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.AccountTokenDirectory;
import com.guardian.identity.domain.TokenPurpose;
import com.guardian.identity.domain.UserId;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Calls the {@code auth_resolve_account_token} {@code SECURITY DEFINER} function from V16.
 *
 * <p>Plain JDBC and {@link Propagation#NOT_SUPPORTED}, for exactly the reasons {@link
 * JdbcPreAuthenticationDirectory} documents: this runs before tenant context exists, so it must not
 * join a transaction whose connection already carries another tenant's {@code SET LOCAL}, and it
 * reaches nothing but the one function. The function returns identifiers only; the token itself is
 * reloaded and judged under ordinary RLS once its tenant is established.
 */
@Component
class JdbcAccountTokenDirectory implements AccountTokenDirectory {

  private final JdbcTemplate jdbcTemplate;

  JdbcAccountTokenDirectory(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  @Transactional(propagation = Propagation.NOT_SUPPORTED)
  public Optional<TokenLocation> resolve(String secretHash, TokenPurpose purpose) {
    List<TokenLocation> found =
        jdbcTemplate.query(
            "SELECT credential_id, user_id, tenant_id FROM auth_resolve_account_token(?, ?)",
            (rs, rowNum) ->
                new TokenLocation(
                    rs.getObject("credential_id", UUID.class),
                    UserId.of(rs.getObject("user_id", UUID.class)),
                    TenantId.of(rs.getObject("tenant_id", UUID.class))),
            secretHash,
            purpose.name());

    // The hash of a 256-bit token collides with nothing in practice; more than one row would be a
    // schema defect rather than an ambiguity to resolve by picking one.
    return found.isEmpty() ? Optional.empty() : Optional.of(found.get(0));
  }
}
