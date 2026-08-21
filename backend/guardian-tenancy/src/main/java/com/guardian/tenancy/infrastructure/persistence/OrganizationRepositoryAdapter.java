package com.guardian.tenancy.infrastructure.persistence;

import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationId;
import java.util.Optional;
import org.springframework.stereotype.Component;

/** Implements the domain-facing {@link OrganizationRepository} over JPA. */
@Component
class OrganizationRepositoryAdapter implements OrganizationRepository {

  private final OrganizationJpaRepository jpaRepository;
  private final OrganizationPersistenceMapper mapper;

  OrganizationRepositoryAdapter(
      OrganizationJpaRepository jpaRepository, OrganizationPersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<Organization> findById(OrganizationId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public Organization save(Organization organization) {
    // Update the managed instance where one exists, so Hibernate's dirty checking and
    // @Version apply — see SchoolRepositoryAdapter.save for why this matters.
    OrganizationEntity entity =
        jpaRepository
            .findById(organization.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, organization);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(organization));

    return mapper.toDomain(jpaRepository.save(entity));
  }
}
