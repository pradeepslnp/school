package com.guardian.tenancy.infrastructure.persistence;

import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationCode;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.OrganizationStatus;
import org.springframework.stereotype.Component;

/** Translates between the domain model and its JPA mapping. */
@Component
class OrganizationPersistenceMapper {

  Organization toDomain(OrganizationEntity entity) {
    return new Organization(
        OrganizationId.of(entity.getId()),
        OrganizationCode.of(entity.getCode()),
        entity.getName(),
        entity.getRegionProfileCode(),
        OrganizationStatus.valueOf(entity.getStatus()),
        entity.getContactEmail(),
        entity.getContactPhone(),
        entity.getVersion());
  }

  OrganizationEntity toEntity(Organization organization) {
    return new OrganizationEntity(
        organization.id().value(),
        organization.code().value(),
        organization.name(),
        organization.regionProfileCode(),
        organization.status().name(),
        organization.contactEmail(),
        organization.contactPhone(),
        organization.version());
  }

  /**
   * Copies mutable state onto a managed entity.
   *
   * <p>Used on update so Hibernate's dirty checking and {@code @Version} apply — see {@link
   * SchoolPersistenceMapper#applyTo} for why this matters.
   */
  void applyTo(OrganizationEntity managed, Organization organization) {
    managed.applyMutableState(
        organization.name(),
        organization.regionProfileCode(),
        organization.status().name(),
        organization.contactEmail(),
        organization.contactPhone());
  }
}
