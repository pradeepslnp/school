package com.guardian.staff.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Package-private — callers use {@link
 * com.guardian.staff.application.port.TransportStaffRepository} via {@link
 * TransportStaffRepositoryAdapter}.
 *
 * <p>No query here filters on {@code tenant_id}: row-level security applies that predicate to every
 * statement (ADR-0001).
 */
interface TransportStaffJpaRepository extends JpaRepository<TransportStaffEntity, UUID> {

  List<TransportStaffEntity> findBySchoolIdOrderByLastNameAscFirstNameAsc(UUID schoolId);

  boolean existsBySchoolIdAndEmployeeCodeAndIdNot(
      UUID schoolId, String employeeCode, UUID excludedId);

  boolean existsBySchoolIdAndEmployeeCode(UUID schoolId, String employeeCode);

  /**
   * A bulk delete, executed immediately so a foreign-key refusal surfaces here rather than at
   * commit. Clears the persistence context so the record just loaded is not flushed back.
   */
  @Modifying(flushAutomatically = true, clearAutomatically = true)
  @Query("DELETE FROM TransportStaffEntity s WHERE s.id = :id")
  int discardById(@Param("id") UUID id);
}
