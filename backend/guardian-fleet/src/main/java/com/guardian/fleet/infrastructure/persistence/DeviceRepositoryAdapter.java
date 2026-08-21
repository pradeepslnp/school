package com.guardian.fleet.infrastructure.persistence;

import com.guardian.fleet.application.port.DeviceRepository;
import com.guardian.fleet.domain.Device;
import com.guardian.fleet.domain.DeviceId;
import com.guardian.fleet.domain.DeviceIdentifier;
import com.guardian.fleet.domain.VehicleId;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

@Component
class DeviceRepositoryAdapter implements DeviceRepository {

  private final DeviceJpaRepository jpaRepository;
  private final DevicePersistenceMapper mapper;

  DeviceRepositoryAdapter(DeviceJpaRepository jpaRepository, DevicePersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<Device> findById(DeviceId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public Optional<Device> findByIdentifierGlobally(DeviceIdentifier deviceIdentifier) {
    return jpaRepository.findByDeviceIdentifier(deviceIdentifier.value()).map(mapper::toDomain);
  }

  @Override
  public List<Device> findByTenant() {
    return jpaRepository.findAllByOrderByDeviceIdentifier().stream().map(mapper::toDomain).toList();
  }

  @Override
  public boolean existsActiveForVehicle(VehicleId vehicleId) {
    return jpaRepository.existsByVehicleIdAndActiveTrue(vehicleId.value());
  }

  @Override
  public Device save(Device device) {
    DeviceEntity entity =
        jpaRepository
            .findById(device.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, device);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(device));

    return mapper.toDomain(jpaRepository.save(entity));
  }
}
