package com.guardian.tenancy.application.command;

import com.guardian.tenancy.domain.Coordinates;
import com.guardian.tenancy.domain.GeofenceRadius;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.SchoolCode;
import java.time.ZoneId;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.tenancy.application.usecase.CreateSchoolUseCase}.
 *
 * <p>Already parsed into domain types — the interface layer converts wire strings into {@link
 * SchoolCode}, {@link ZoneId}, and {@link Coordinates}, so malformed input fails at the boundary
 * rather than inside a use case.
 */
public record CreateSchoolCommand(
    OrganizationId organizationId,
    SchoolCode code,
    String name,
    ZoneId timezone,
    Coordinates location,
    GeofenceRadius geofenceRadius,
    UUID actorId,
    String actorRole) {

  public CreateSchoolCommand {
    Objects.requireNonNull(organizationId, "organizationId");
    Objects.requireNonNull(code, "code");
    Objects.requireNonNull(name, "name");
    Objects.requireNonNull(timezone, "timezone");
    Objects.requireNonNull(location, "location");
    Objects.requireNonNull(geofenceRadius, "geofenceRadius");
  }
}
