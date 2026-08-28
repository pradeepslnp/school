package com.guardian.identity.application.port;

import com.guardian.identity.domain.AccountToken;
import com.guardian.identity.domain.TokenPurpose;
import com.guardian.identity.domain.UserId;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for invitation and password-reset link tokens (ADR-0012).
 *
 * <p>Tenant-scoped by row-level security like everything carrying {@code tenant_id}; these reads and
 * writes run inside the tenant established after the pre-auth {@link AccountTokenDirectory} lookup.
 * Accumulates one row per token issued (matching {@code OtpCredentialRepository}), so re-issuing an
 * invitation supersedes by recency rather than mutating the previous row.
 */
public interface AccountTokenRepository {

  AccountToken save(AccountToken token);

  /** Loads one token by its credential id — the row a pre-auth resolve pointed at. */
  Optional<AccountToken> findById(UUID id);

  /** The most recent still-unconsumed token of this purpose for the user, if any. */
  Optional<AccountToken> findLatestUnconsumed(UserId userId, TokenPurpose purpose);
}
