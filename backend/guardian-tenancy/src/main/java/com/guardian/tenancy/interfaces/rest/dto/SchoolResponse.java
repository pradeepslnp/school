package com.guardian.tenancy.interfaces.rest.dto;

import com.guardian.tenancy.domain.School;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * Wire representation of a school.
 *
 * <p>A separate type from the domain model so the API contract can stay stable while the domain
 * evolves — and so a domain object is never serialised directly to a client.
 */
public record SchoolResponse(
    UUID id,
    UUID organizationId,
    String code,
    String name,
    String timezone,
    BigDecimal latitude,
    BigDecimal longitude,
    int geofenceRadiusM,
    String status) {

  public static SchoolResponse from(School school) {
    return new SchoolResponse(
        school.id().value(),
        school.organizationId().value(),
        school.code().value(),
        school.name(),
        school.timezone().getId(),
        school.location().latitude(),
        school.location().longitude(),
        school.geofenceRadius().metres(),
        school.status().name());
  }
}
