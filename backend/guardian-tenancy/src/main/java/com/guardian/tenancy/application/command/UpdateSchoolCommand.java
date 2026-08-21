package com.guardian.tenancy.application.command;

import com.guardian.tenancy.domain.Coordinates;
import com.guardian.tenancy.domain.GeofenceRadius;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.SchoolId;
import java.time.ZoneId;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.tenancy.application.usecase.UpdateSchoolUseCase}.
 *
 * <p>Carries {@code organizationId} even though the URL only names the school: the tenant a
 * school's row lives under is its organization, and — same as {@code CreateOrganizationCommand} —
 * establishing that tenant context is the caller's job here, not something the use case can
 * discover by reading a row it cannot yet see. See the use case's own documentation.
 */
public record UpdateSchoolCommand(
    SchoolId id,
    OrganizationId organizationId,
    String name,
    ZoneId timezone,
    Coordinates location,
    GeofenceRadius geofenceRadius,
    UUID actorId,
    String actorRole) {

  public UpdateSchoolCommand {
    Objects.requireNonNull(id, "id");
    Objects.requireNonNull(organizationId, "organizationId");
    Objects.requireNonNull(name, "name");
    Objects.requireNonNull(timezone, "timezone");
    Objects.requireNonNull(location, "location");
    Objects.requireNonNull(geofenceRadius, "geofenceRadius");
  }
}
