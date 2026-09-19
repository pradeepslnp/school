package com.guardian.staff.infrastructure.persistence;

import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.TransportStaff;
import java.util.List;
import java.util.Optional;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;

/** Implements the domain-facing {@link TransportStaffRepository} over JPA. */
@Component
class TransportStaffRepositoryAdapter implements TransportStaffRepository {

  private final TransportStaffJpaRepository jpaRepository;
  private final TransportStaffPersistenceMapper mapper;

  TransportStaffRepositoryAdapter(
      TransportStaffJpaRepository jpaRepository, TransportStaffPersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<TransportStaff> findById(StaffId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public List<TransportStaff> findBySchool(SchoolId schoolId) {
    return jpaRepository.findBySchoolIdOrderByLastNameAscFirstNameAsc(schoolId.value()).stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public boolean existsByEmployeeCode(
      SchoolId schoolId, String employeeCode, StaffId excludingStaffId) {
    return excludingStaffId == null
        ? jpaRepository.existsBySchoolIdAndEmployeeCode(schoolId.value(), employeeCode)
        : jpaRepository.existsBySchoolIdAndEmployeeCodeAndIdNot(
            schoolId.value(), employeeCode, excludingStaffId.value());
  }

  @Override
  public TransportStaff save(TransportStaff staff) {
    TransportStaffEntity entity =
        jpaRepository
            .findById(staff.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, staff);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(staff));

    return mapper.toDomain(jpaRepository.save(entity));
  }

  @Override
  public boolean discard(StaffId id) {
    try {
      jpaRepository.discardById(id.value());
      return true;
    } catch (DataIntegrityViolationException stillReferenced) {
      // A DELETE can violate nothing but a foreign key: some other row still points at this
      // record, which is exactly the history BR-STAFF-007 protects.
      return false;
    }
  }
}
