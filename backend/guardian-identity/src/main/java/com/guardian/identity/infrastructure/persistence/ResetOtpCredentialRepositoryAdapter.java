package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantContext;
import com.guardian.identity.application.port.ResetOtpCredentialRepository;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.UserId;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Implements {@link ResetOtpCredentialRepository} over JPA, storing the reset code under
 * {@code credential_type = 'RESET'} in {@code user_credentials} (ADR-0012).
 *
 * <p>A near-copy of {@link OtpCredentialRepositoryAdapter} on a different {@code credential_type} —
 * the duplication is deliberate. Merging them behind a "type" parameter would make it one edit away
 * to read a sign-in code where a reset code was meant, which is exactly the confusion the separate
 * types exist to prevent.
 */
@Component
class ResetOtpCredentialRepositoryAdapter implements ResetOtpCredentialRepository {

  private static final String RESET = "RESET";

  private final UserCredentialJpaRepository jpaRepository;

  ResetOtpCredentialRepositoryAdapter(UserCredentialJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Optional<OtpCredential> findLatest(UserId userId) {
    return jpaRepository
        .findFirstByUserIdAndCredentialTypeOrderByCreatedAtDesc(userId.value(), RESET)
        .map(ResetOtpCredentialRepositoryAdapter::toDomain);
  }

  @Override
  public OtpCredential save(OtpCredential credential) {
    Optional<UserCredentialEntity> managed = jpaRepository.findById(credential.id());

    if (managed.isPresent()) {
      UserCredentialEntity entity = managed.get();
      entity.applyAttemptState(
          credential.consumedAt(), credential.failedAttempts(), credential.lockedUntil());
      return toDomain(jpaRepository.save(entity));
    }

    // tenant_id comes from the context established by TenantScopedTransaction, never the caller —
    // see OtpCredentialRepositoryAdapter.save for why that matters even under RLS WITH CHECK.
    UserCredentialEntity entity =
        new UserCredentialEntity(
            credential.id(),
            TenantContext.require().value(),
            credential.userId().value(),
            RESET,
            credential.secretHash(),
            credential.expiresAt(),
            credential.consumedAt(),
            credential.failedAttempts(),
            credential.lockedUntil());

    return toDomain(jpaRepository.save(entity));
  }

  private static OtpCredential toDomain(UserCredentialEntity entity) {
    return OtpCredential.rehydrate(
        entity.getId(),
        UserId.of(entity.getUserId()),
        entity.getSecretHash(),
        entity.getExpiresAt(),
        entity.getConsumedAt(),
        entity.getFailedAttempts(),
        entity.getLockedUntil(),
        entity.getVersion());
  }
}
