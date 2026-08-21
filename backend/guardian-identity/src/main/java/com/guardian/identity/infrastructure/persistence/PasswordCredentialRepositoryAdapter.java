package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantContext;
import com.guardian.identity.application.port.PasswordCredentialRepository;
import com.guardian.identity.domain.PasswordCredential;
import com.guardian.identity.domain.UserId;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Implements {@link PasswordCredentialRepository} over JPA, sharing {@code user_credentials} with
 * {@link OtpCredentialRepositoryAdapter} via {@code credential_type}.
 */
@Component
class PasswordCredentialRepositoryAdapter implements PasswordCredentialRepository {

  private static final String PASSWORD = "PASSWORD";

  private final UserCredentialJpaRepository jpaRepository;

  PasswordCredentialRepositoryAdapter(UserCredentialJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Optional<PasswordCredential> findByUserId(UserId userId) {
    return jpaRepository
        .findFirstByUserIdAndCredentialTypeOrderByCreatedAtDesc(userId.value(), PASSWORD)
        .map(PasswordCredentialRepositoryAdapter::toDomain);
  }

  @Override
  public PasswordCredential save(PasswordCredential credential) {
    Optional<UserCredentialEntity> managed = jpaRepository.findById(credential.id());

    if (managed.isPresent()) {
      UserCredentialEntity entity = managed.get();
      // A password row carries no expiry or consumed-at; only the attempt state changes across
      // a sign-in, which is exactly what applyAttemptState updates.
      entity.applyAttemptState(null, credential.failedAttempts(), credential.lockedUntil());
      return toDomain(jpaRepository.save(entity));
    }

    // tenant_id comes from the context established by TenantScopedTransaction, never from the
    // caller — see OtpCredentialRepositoryAdapter.save for why that matters even though RLS
    // WITH CHECK would also reject a mismatched tenant.
    UserCredentialEntity entity =
        new UserCredentialEntity(
            credential.id(),
            TenantContext.require().value(),
            credential.userId().value(),
            PASSWORD,
            credential.secretHash(),
            null,
            null,
            credential.failedAttempts(),
            credential.lockedUntil());

    return toDomain(jpaRepository.save(entity));
  }

  private static PasswordCredential toDomain(UserCredentialEntity entity) {
    return PasswordCredential.rehydrate(
        entity.getId(),
        UserId.of(entity.getUserId()),
        entity.getSecretHash(),
        entity.getFailedAttempts(),
        entity.getLockedUntil(),
        entity.getVersion());
  }
}
