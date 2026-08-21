package com.guardian.fleet.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.domain.Device;
import com.guardian.fleet.domain.DeviceId;
import com.guardian.fleet.domain.DeviceIdentifier;
import com.guardian.fleet.domain.VehicleId;
import org.springframework.stereotype.Component;

@Component
class DevicePersistenceMapper {

  Device toDomain(DeviceEntity entity) {
    return new Device(
        DeviceId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        entity.getVehicleId() == null ? null : VehicleId.of(entity.getVehicleId()),
        DeviceIdentifier.of(entity.getDeviceIdentifier()),
        entity.getVendorCode(),
        entity.getCredentialHash(),
        entity.getLastSeenAt(),
        entity.isActive(),
        entity.getVersion());
  }

  DeviceEntity toEntity(Device device) {
    return new DeviceEntity(
        device.id().value(),
        device.tenantId().value(),
        device.vehicleId().map(VehicleId::value).orElse(null),
        device.deviceIdentifier().value(),
        device.vendorCode(),
        device.credentialHash(),
        device.lastSeenAt().orElse(null),
        device.active(),
        device.version());
  }

  void applyTo(DeviceEntity managed, Device device) {
    managed.applyMutableState(
        device.vehicleId().map(VehicleId::value).orElse(null),
        device.lastSeenAt().orElse(null),
        device.active());
  }
}
