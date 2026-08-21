package com.guardian.identity.infrastructure.persistence;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Spring Data repository for {@code users}. Package-private — callers use {@link
 * com.guardian.identity.application.port.UserRepository}.
 *
 * <p>Nothing here filters on {@code tenant_id}: row-level security applies that predicate to every
 * statement (ADR-0001). Adding an application-level filter would imply isolation depends on
 * remembering it.
 */
interface UserJpaRepository extends JpaRepository<UserEntity, UUID> {

  /**
   * Whichever row this tenant already has for the number, if any (feature STF-001). RLS scopes this
   * to the caller's own tenant the same as every other query here — see this interface's own
   * documentation.
   */
  Optional<UserEntity> findByPhone(String phone);

  /**
   * Role codes currently assigned to a user.
   *
   * <p>A native query because {@code roles} and {@code user_roles} have no entities — this
   * projection is all authentication needs of them, and mapping two tables to get a list of strings
   * would be weight with no reader.
   */
  @Query(
      value =
          """
          SELECT r.code
          FROM user_roles ur
          JOIN roles r ON r.id = ur.role_id
          WHERE ur.user_id = :userId
          ORDER BY r.code
          """,
      nativeQuery = true)
  List<String> findRoleCodes(@Param("userId") UUID userId);
}
