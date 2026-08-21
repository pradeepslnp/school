package com.guardian.tenancy.infrastructure.persistence;

import com.guardian.tenancy.application.port.SchoolRepository;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolCode;
import com.guardian.tenancy.domain.SchoolId;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

/** Implements the domain-facing {@link SchoolRepository} over JPA. */
@Component
class SchoolRepositoryAdapter implements SchoolRepository {

  private final SchoolJpaRepository jpaRepository;
  private final SchoolPersistenceMapper mapper;

  SchoolRepositoryAdapter(SchoolJpaRepository jpaRepository, SchoolPersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<School> findById(SchoolId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public Optional<School> findByCode(OrganizationId organizationId, SchoolCode code) {
    return jpaRepository
        .findByOrganizationIdAndCode(organizationId.value(), code.value())
        .map(mapper::toDomain);
  }

  @Override
  public List<School> findActiveByOrganization(OrganizationId organizationId) {
    return jpaRepository.findActiveByOrganization(organizationId.value()).stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public boolean existsByCode(OrganizationId organizationId, SchoolCode code) {
    return jpaRepository.existsByOrganizationIdAndCode(organizationId.value(), code.value());
  }

  @Override
  public long countActiveByOrganization(OrganizationId organizationId) {
    return jpaRepository.countActiveByOrganization(organizationId.value());
  }

  @Override
  public School save(School school) {
    // Update the managed instance where one exists, so Hibernate's dirty checking and
    // @Version apply. Persisting a freshly built detached entity would bypass optimistic
    // locking and let a concurrent edit silently win.
    SchoolEntity entity =
        jpaRepository
            .findById(school.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, school);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(school));

    return mapper.toDomain(jpaRepository.save(entity));
  }
}
