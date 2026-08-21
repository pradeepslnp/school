package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantContext;
import com.guardian.identity.application.port.OtpCredentialRepository;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.UserId;
import java.util.Optional;
import org.springframework.stereotype.Component;

/** Implements {@link OtpCredentialRepository} over JPA. */
@Component
class OtpCredentialRepositoryAdapter implements OtpCredentialRepository {

  private static final String OTP = "OTP";

  private final UserCredentialJpaRepository jpaRepository;

  OtpCredentialRepositoryAdapter(UserCredentialJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Optional<OtpCredential> findLatestUnconsumed(UserId userId) {
    return jpaRepository
        .findFirstByUserIdAndCredentialTypeAndConsumedAtIsNullOrderByCreatedAtDesc(
            userId.value(), OTP)
        .map(OtpCredentialRepositoryAdapter::toDomain);
  }

  @Override
  public Optional<OtpCredential> findLatest(UserId userId) {
    return jpaRepository
        .findFirstByUserIdAndCredentialTypeOrderByCreatedAtDesc(userId.value(), OTP)
        .map(OtpCredentialRepositoryAdapter::toDomain);
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

    // tenant_id comes from the context established by TenantScopedTransaction, never from the
    // caller. Even if it did, the RLS WITH CHECK clause would reject a row bearing another
    // tenant's id — the two controls are independent on purpose.
    UserCredentialEntity entity =
        new UserCredentialEntity(
            credential.id(),
            TenantContext.require().value(),
            credential.userId().value(),
            OTP,
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
