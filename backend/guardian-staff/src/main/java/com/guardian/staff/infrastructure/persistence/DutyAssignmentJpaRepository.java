package com.guardian.staff.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface DutyAssignmentJpaRepository extends JpaRepository<DutyAssignmentEntity, UUID> {

  List<DutyAssignmentEntity> findByRouteIdAndActiveTrue(UUID routeId);
}
