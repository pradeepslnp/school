package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantContext;
import com.guardian.identity.application.port.LoginOtpCredentialRepository;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.UserId;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Implements {@link LoginOtpCredentialRepository} over JPA, storing the emailed sign-in code under
 * {@code credential_type = 'LOGIN_OTP'} (V17).
 *
 * <p>A near-copy of the phone-OTP and reset-OTP adapters on a different type. The duplication is
 * deliberate for the same reason stated there: collapsing them behind a type parameter would make
 * it one careless argument away to check a sign-in code against a reset credential.
 */
@Component
class LoginOtpCredentialRepositoryAdapter implements LoginOtpCredentialRepository {

  private static final String LOGIN_OTP = "LOGIN_OTP";

  private final UserCredentialJpaRepository jpaRepository;

  LoginOtpCredentialRepositoryAdapter(UserCredentialJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Optional<OtpCredential> findLatest(UserId userId) {
    return jpaRepository
        .findFirstByUserIdAndCredentialTypeOrderByCreatedAtDesc(userId.value(), LOGIN_OTP)
        .map(LoginOtpCredentialRepositoryAdapter::toDomain);
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

    UserCredentialEntity entity =
        new UserCredentialEntity(
            credential.id(),
            TenantContext.require().value(),
            credential.userId().value(),
            LOGIN_OTP,
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
