package com.guardian.fleet.application.port;

import com.guardian.fleet.domain.Device;
import com.guardian.fleet.domain.DeviceId;
import com.guardian.fleet.domain.DeviceIdentifier;
import com.guardian.fleet.domain.VehicleId;
import java.util.List;
import java.util.Optional;

public interface DeviceRepository {

  Optional<Device> findById(DeviceId id);

  /**
   * Looked up by identifier alone, without a tenant filter — ingestion resolves the device
   * <em>before</em> it knows the tenant
   * (guardian-docs/02-system-design/REALTIME_TRACKING_DESIGN.md). {@code device_identifier} is
   * globally unique for exactly this reason. Callers other than ingestion should prefer {@link
   * #findById}.
   */
  Optional<Device> findByIdentifierGlobally(DeviceIdentifier deviceIdentifier);

  List<Device> findByTenant();

  boolean existsActiveForVehicle(VehicleId vehicleId);

  Device save(Device device);
}
