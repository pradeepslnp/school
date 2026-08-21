package com.guardian.tenancy.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.tenancy.domain.Coordinates;
import com.guardian.tenancy.domain.GeofenceRadius;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolCode;
import com.guardian.tenancy.domain.SchoolId;
import com.guardian.tenancy.domain.SchoolStatus;
import java.time.ZoneId;
import org.springframework.stereotype.Component;

/** Translates between the domain model and its JPA mapping. */
@Component
class SchoolPersistenceMapper {

  School toDomain(SchoolEntity entity) {
    return new School(
        SchoolId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        OrganizationId.of(entity.getOrganizationId()),
        SchoolCode.of(entity.getCode()),
        entity.getName(),
        ZoneId.of(entity.getTimezone()),
        new Coordinates(entity.getLatitude(), entity.getLongitude()),
        GeofenceRadius.ofMetres(entity.getGeofenceRadiusM()),
        SchoolStatus.valueOf(entity.getStatus()),
        entity.getVersion());
  }

  SchoolEntity toEntity(School school) {
    return new SchoolEntity(
        school.id().value(),
        school.tenantId().value(),
        school.organizationId().value(),
        school.code().value(),
        school.name(),
        school.timezone().getId(),
        school.location().latitude(),
        school.location().longitude(),
        school.geofenceRadius().metres(),
        school.status().name(),
        school.version());
  }

  /**
   * Copies mutable state onto a managed entity.
   *
   * <p>Used on update so Hibernate's dirty checking and {@code @Version} apply. Constructing a
   * detached entity and merging would bypass optimistic locking and let a concurrent edit silently
   * win.
   */
  void applyTo(SchoolEntity managed, School school) {
    managed.applyMutableState(
        school.name(),
        school.location().latitude(),
        school.location().longitude(),
        school.geofenceRadius().metres(),
        school.status().name());
  }
}
