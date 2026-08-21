package com.guardian.tenancy.interfaces.rest.dto;

import com.guardian.tenancy.domain.Organization;
import java.util.UUID;

/**
 * Wire representation of an organization.
 *
 * <p>A separate type from the domain model so the API contract can stay stable while the domain
 * evolves — matching {@code SchoolResponse}.
 */
public record OrganizationResponse(
    UUID id,
    String code,
    String name,
    String regionProfileCode,
    String status,
    String contactEmail,
    String contactPhone) {

  public static OrganizationResponse from(Organization organization) {
    return new OrganizationResponse(
        organization.id().value(),
        organization.code().value(),
        organization.name(),
        organization.regionProfileCode(),
        organization.status().name(),
        organization.contactEmail(),
        organization.contactPhone());
  }
}
