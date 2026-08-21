package com.guardian.identity.infrastructure.persistence;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@code user_credentials}. Package-private. */
interface UserCredentialJpaRepository extends JpaRepository<UserCredentialEntity, UUID> {

  Optional<UserCredentialEntity> findFirstByUserIdAndCredentialTypeOrderByCreatedAtDesc(
      UUID userId, String credentialType);

  Optional<UserCredentialEntity>
      findFirstByUserIdAndCredentialTypeAndConsumedAtIsNullOrderByCreatedAtDesc(
          UUID userId, String credentialType);
}
