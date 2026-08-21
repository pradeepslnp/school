package com.guardian.staff.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

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
}
