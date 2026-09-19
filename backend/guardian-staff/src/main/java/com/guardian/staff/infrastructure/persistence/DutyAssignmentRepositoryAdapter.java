package com.guardian.staff.infrastructure.persistence;

import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.DutyAssignmentId;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.StaffId;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

/** Implements the domain-facing {@link DutyAssignmentRepository} over JPA. */
@Component
class DutyAssignmentRepositoryAdapter implements DutyAssignmentRepository {

  private final DutyAssignmentJpaRepository jpaRepository;
  private final DutyAssignmentPersistenceMapper mapper;

  DutyAssignmentRepositoryAdapter(
      DutyAssignmentJpaRepository jpaRepository, DutyAssignmentPersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<DutyAssignment> findById(DutyAssignmentId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public List<DutyAssignment> findByRoute(RouteId routeId) {
    return jpaRepository.findByRouteIdAndActiveTrue(routeId.value()).stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public List<DutyAssignment> findActiveByStaff(StaffId staffId) {
    return jpaRepository.findByStaffIdAndActiveTrue(staffId.value()).stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public DutyAssignment save(DutyAssignment assignment) {
    DutyAssignmentEntity entity =
        jpaRepository
            .findById(assignment.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, assignment);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(assignment));

    return mapper.toDomain(jpaRepository.save(entity));
  }

  @Override
  public int deleteAllForStaff(StaffId staffId) {
    return jpaRepository.deleteAllByStaffId(staffId.value());
  }
}
