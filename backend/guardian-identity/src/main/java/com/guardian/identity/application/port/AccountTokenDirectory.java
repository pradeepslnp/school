package com.guardian.identity.application.port;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.domain.TokenPurpose;
import com.guardian.identity.domain.UserId;
import java.util.Optional;
import java.util.UUID;

/**
 * Resolves a link token to its account without tenant context (ADR-0012).
 *
 * <p>The accept-invitation and reset-password endpoints have the same bootstrap problem as login
 * (see {@link PreAuthenticationDirectory}): the caller presents only a token, so row-level security
 * has no {@code app.tenant_id} to work with, and something must cross tenants once to answer "whose
 * token is this?". This is that something, kept to the same narrow shape — it returns identifiers
 * only, never credential material or profile data, and is implemented by a {@code SECURITY DEFINER}
 * function granted narrowly to the application role (V16), not by giving that role BYPASSRLS.
 *
 * <p>Kept as its own port rather than a fourth method on {@link PreAuthenticationDirectory}, whose
 * own documentation warns that every method added there widens the one path that is not
 * tenant-isolated. This is a different credential kind resolved by a different function; a separate
 * port keeps each one's surface legible.
 */
public interface AccountTokenDirectory {

  /**
   * The account a token of this purpose belongs to, by the token's stored hash. Empty when nothing
   * matches — the ordinary "bad or forged link" case.
   */
  Optional<TokenLocation> resolve(String secretHash, TokenPurpose purpose);

  /** Just enough to establish tenant context and reload the token under RLS. */
  record TokenLocation(UUID credentialId, UserId userId, TenantId tenantId) {}
}
