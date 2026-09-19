package com.guardian.staff.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface DutyAssignmentJpaRepository extends JpaRepository<DutyAssignmentEntity, UUID> {

  List<DutyAssignmentEntity> findByRouteIdAndActiveTrue(UUID routeId);

  List<DutyAssignmentEntity> findByStaffIdAndActiveTrue(UUID staffId);

  @Modifying(flushAutomatically = true)
  @Query("DELETE FROM DutyAssignmentEntity d WHERE d.staffId = :staffId")
  int deleteAllByStaffId(@Param("staffId") UUID staffId);
}
