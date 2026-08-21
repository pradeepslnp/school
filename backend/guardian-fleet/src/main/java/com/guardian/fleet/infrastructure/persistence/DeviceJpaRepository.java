package com.guardian.fleet.infrastructure.persistence;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Package-private — callers use {@link com.guardian.fleet.application.port.DeviceRepository} via
 * {@link DeviceRepositoryAdapter}.
 *
 * <p>{@link #findByDeviceIdentifier} deliberately has no tenant scoping in its name or its query:
 * device identifiers are globally unique and ingestion resolves the device before it knows the
 * tenant. Every other method here is implicitly tenant-scoped by row-level security.
 */
interface DeviceJpaRepository extends JpaRepository<DeviceEntity, UUID> {

  Optional<DeviceEntity> findByDeviceIdentifier(String deviceIdentifier);

  List<DeviceEntity> findAllByOrderByDeviceIdentifier();

  boolean existsByVehicleIdAndActiveTrue(UUID vehicleId);
}
