package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantContext;
import com.guardian.identity.application.port.AccountTokenRepository;
import com.guardian.identity.domain.AccountToken;
import com.guardian.identity.domain.TokenPurpose;
import com.guardian.identity.domain.UserId;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Implements {@link AccountTokenRepository} over JPA, sharing {@code user_credentials} with the
 * password and OTP adapters via {@code credential_type} (ADR-0012).
 */
@Component
class AccountTokenRepositoryAdapter implements AccountTokenRepository {

  private final UserCredentialJpaRepository jpaRepository;

  AccountTokenRepositoryAdapter(UserCredentialJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public AccountToken save(AccountToken token) {
    Optional<UserCredentialEntity> managed = jpaRepository.findById(token.id());

    if (managed.isPresent()) {
      // The only mutation a link token undergoes is being consumed. Its hash and expiry are
      // fixed at issue, so the attempt columns (unused for link tokens) stay zeroed.
      UserCredentialEntity entity = managed.get();
      entity.applyAttemptState(token.consumedAt(), 0, null);
      return toDomain(jpaRepository.save(entity));
    }

    // tenant_id comes from the context established by TenantScopedTransaction, never the caller —
    // and RLS WITH CHECK would reject a mismatched tenant regardless (see
    // OtpCredentialRepositoryAdapter.save).
    UserCredentialEntity entity =
        new UserCredentialEntity(
            token.id(),
            TenantContext.require().value(),
            token.userId().value(),
            token.purpose().name(),
            token.secretHash(),
            token.expiresAt(),
            token.consumedAt(),
            0,
            null);

    return toDomain(jpaRepository.save(entity));
  }

  @Override
  public Optional<AccountToken> findById(UUID id) {
    return jpaRepository
        .findById(id)
        .filter(AccountTokenRepositoryAdapter::isLinkToken)
        .map(AccountTokenRepositoryAdapter::toDomain);
  }

  @Override
  public Optional<AccountToken> findLatestUnconsumed(UserId userId, TokenPurpose purpose) {
    return jpaRepository
        .findFirstByUserIdAndCredentialTypeAndConsumedAtIsNullOrderByCreatedAtDesc(
            userId.value(), purpose.name())
        .map(AccountTokenRepositoryAdapter::toDomain);
  }

  private static boolean isLinkToken(UserCredentialEntity entity) {
    // Only invitations use link tokens now — password reset moved to an emailed OTP stored under
    // credential_type RESET, which this adapter must never map as an AccountToken (ADR-0012).
    return TokenPurpose.INVITE.name().equals(entity.getCredentialType());
  }

  private static AccountToken toDomain(UserCredentialEntity entity) {
    return AccountToken.rehydrate(
        entity.getId(),
        UserId.of(entity.getUserId()),
        TokenPurpose.fromStored(entity.getCredentialType()),
        entity.getSecretHash(),
        entity.getExpiresAt(),
        entity.getConsumedAt(),
        entity.getVersion());
  }
}
