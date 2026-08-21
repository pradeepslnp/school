package com.guardian.staff.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.staff.domain.Direction;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.DutyAssignmentId;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import org.springframework.stereotype.Component;

/** Translates between the domain model and its JPA mapping. */
@Component
class DutyAssignmentPersistenceMapper {

  DutyAssignment toDomain(DutyAssignmentEntity entity) {
    return new DutyAssignment(
        DutyAssignmentId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        StaffId.of(entity.getStaffId()),
        RouteId.of(entity.getRouteId()),
        StaffType.valueOf(entity.getRole()),
        entity.getDirection() == null ? null : Direction.valueOf(entity.getDirection()),
        entity.getEffectiveFrom(),
        entity.getEffectiveUntil(),
        entity.isActive(),
        entity.getVersion());
  }

  DutyAssignmentEntity toEntity(DutyAssignment assignment) {
    return new DutyAssignmentEntity(
        assignment.id().value(),
        assignment.tenantId().value(),
        assignment.staffId().value(),
        assignment.routeId().value(),
        assignment.role().name(),
        assignment.direction().map(Enum::name).orElse(null),
        assignment.effectiveFrom(),
        assignment.effectiveUntil().orElse(null),
        assignment.active(),
        assignment.version());
  }

  /**
   * Copies mutable state onto a managed entity, so Hibernate's dirty checking and {@code @Version}
   * apply. Persisting a freshly built detached entity would bypass optimistic locking and let a
   * concurrent edit silently win.
   */
  void applyTo(DutyAssignmentEntity managed, DutyAssignment assignment) {
    managed.applyMutableState(assignment.effectiveUntil().orElse(null), assignment.active());
  }
}
