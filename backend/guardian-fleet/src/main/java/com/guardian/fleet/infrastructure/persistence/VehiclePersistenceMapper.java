package com.guardian.fleet.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.domain.RegistrationNo;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.SeatingCapacity;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleId;
import com.guardian.fleet.domain.VehicleStatus;
import com.guardian.fleet.domain.VehicleType;
import org.springframework.stereotype.Component;

/** Translates between the domain model and its JPA mapping. */
@Component
class VehiclePersistenceMapper {

  Vehicle toDomain(VehicleEntity entity) {
    return new Vehicle(
        VehicleId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        SchoolId.of(entity.getSchoolId()),
        RegistrationNo.of(entity.getRegistrationNo()),
        entity.getDisplayName(),
        VehicleType.valueOf(entity.getVehicleType()),
        SeatingCapacity.of(entity.getSeatingCapacity()),
        entity.getVendorName(),
        VehicleStatus.valueOf(entity.getStatus()),
        entity.getVersion());
  }

  VehicleEntity toEntity(Vehicle vehicle) {
    return new VehicleEntity(
        vehicle.id().value(),
        vehicle.tenantId().value(),
        vehicle.schoolId().value(),
        vehicle.registrationNo().value(),
        vehicle.displayName(),
        vehicle.vehicleType().name(),
        vehicle.seatingCapacity().seats(),
        vehicle.vendorName().orElse(null),
        vehicle.status().name(),
        vehicle.version());
  }

  /**
   * Copies mutable state onto a managed entity, so Hibernate's dirty checking and {@code @Version}
   * apply. Persisting a freshly built detached entity would bypass optimistic locking and let a
   * concurrent edit silently win.
   */
  void applyTo(VehicleEntity managed, Vehicle vehicle) {
    managed.applyMutableState(
        vehicle.displayName(),
        vehicle.seatingCapacity().seats(),
        vehicle.vendorName().orElse(null),
        vehicle.status().name());
  }
}
