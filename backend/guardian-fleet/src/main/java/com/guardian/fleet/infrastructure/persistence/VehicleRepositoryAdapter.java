package com.guardian.fleet.infrastructure.persistence;

import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.domain.RegistrationNo;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleId;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

/** Implements the domain-facing {@link VehicleRepository} over JPA. */
@Component
class VehicleRepositoryAdapter implements VehicleRepository {

  private final VehicleJpaRepository jpaRepository;
  private final VehiclePersistenceMapper mapper;

  VehicleRepositoryAdapter(VehicleJpaRepository jpaRepository, VehiclePersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<Vehicle> findById(VehicleId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public List<Vehicle> findBySchool(SchoolId schoolId) {
    return jpaRepository.findBySchoolIdOrderByDisplayName(schoolId.value()).stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public boolean existsByRegistrationNo(RegistrationNo registrationNo) {
    return jpaRepository.existsByRegistrationNo(registrationNo.value());
  }

  @Override
  public Vehicle save(Vehicle vehicle) {
    VehicleEntity entity =
        jpaRepository
            .findById(vehicle.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, vehicle);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(vehicle));

    return mapper.toDomain(jpaRepository.save(entity));
  }
}
