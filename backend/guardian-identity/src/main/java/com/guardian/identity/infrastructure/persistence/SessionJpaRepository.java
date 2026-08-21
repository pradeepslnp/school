package com.guardian.identity.infrastructure.persistence;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data repository for {@code sessions}. Package-private. */
interface SessionJpaRepository extends JpaRepository<SessionEntity, UUID> {

  /**
   * Revokes every live session in a rotation family in one statement (BR-IAM-009).
   *
   * <p>A bulk update rather than a load-and-save loop, because it must be atomic. Iterating leaves
   * a window in which some of the family is revoked and the rest is not — and the rest is exactly
   * what an attacker holding the stolen token is using.
   *
   * <p>{@code clearAutomatically} matters: a bulk update bypasses the persistence context, so any
   * {@link SessionEntity} already loaded in this transaction would still show {@code revoked =
   * false} and could write that stale value back on flush.
   */
  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query(
      """
      UPDATE SessionEntity s
      SET s.revoked = true,
          s.revokedReason = :reason
      WHERE s.familyId = :familyId AND s.revoked = false
      """)
  int revokeFamily(@Param("familyId") UUID familyId, @Param("reason") String reason);
}
