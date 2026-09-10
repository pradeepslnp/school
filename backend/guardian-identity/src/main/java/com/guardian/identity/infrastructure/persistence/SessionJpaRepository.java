package com.guardian.identity.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data repository for {@code sessions}. Package-private. */
interface SessionJpaRepository extends JpaRepository<SessionEntity, UUID> {

  /**
   * One user's sessions, newest first (IAM-004). Row-level security scopes this to the current
   * tenant, so it never needs a {@code tenant_id} predicate of its own.
   */
  List<SessionEntity> findByUserIdOrderByIssuedAtDesc(UUID userId);

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

  /**
   * Revokes every live session for one user in one statement (ADR-0012, password reset).
   *
   * <p>Bulk update with {@code clearAutomatically} for the same reasons as {@link #revokeFamily}:
   * atomicity, and so a {@link SessionEntity} already loaded this transaction cannot write a stale
   * {@code revoked = false} back on flush.
   */
  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query(
      """
      UPDATE SessionEntity s
      SET s.revoked = true,
          s.revokedReason = :reason
      WHERE s.userId = :userId AND s.revoked = false
      """)
  int revokeAllForUser(@Param("userId") UUID userId, @Param("reason") String reason);
}
