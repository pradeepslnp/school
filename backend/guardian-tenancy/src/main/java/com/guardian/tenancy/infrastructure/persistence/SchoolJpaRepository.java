package com.guardian.tenancy.infrastructure.persistence;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Spring Data repository. Package-private — callers use {@link
 * com.guardian.tenancy.application.port.SchoolRepository} via {@link SchoolRepositoryAdapter}.
 *
 * <p>No query here filters on {@code tenant_id}. That is deliberate, not an omission: row-level
 * security applies the predicate to every statement (ADR-0001). Adding an application-level filter
 * would suggest isolation depends on remembering it, and the whole point of ADR-0001 is that it
 * does not.
 */
interface SchoolJpaRepository extends JpaRepository<SchoolEntity, UUID> {

  Optional<SchoolEntity> findByOrganizationIdAndCode(UUID organizationId, String code);

  boolean existsByOrganizationIdAndCode(UUID organizationId, String code);

  @Query(
      """
      SELECT s FROM SchoolEntity s
      WHERE s.organizationId = :organizationId AND s.status = 'ACTIVE'
      ORDER BY s.name
      """)
  List<SchoolEntity> findActiveByOrganization(@Param("organizationId") UUID organizationId);

  @Query(
      """
      SELECT COUNT(s) FROM SchoolEntity s
      WHERE s.organizationId = :organizationId AND s.status = 'ACTIVE'
      """)
  long countActiveByOrganization(@Param("organizationId") UUID organizationId);
}
