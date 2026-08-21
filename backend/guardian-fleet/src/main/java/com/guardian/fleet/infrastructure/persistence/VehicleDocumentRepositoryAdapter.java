package com.guardian.fleet.infrastructure.persistence;

import com.guardian.fleet.application.port.VehicleDocumentRepository;
import com.guardian.fleet.domain.VehicleDocument;
import com.guardian.fleet.domain.VehicleDocumentId;
import com.guardian.fleet.domain.VehicleId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

@Component
class VehicleDocumentRepositoryAdapter implements VehicleDocumentRepository {

  private final VehicleDocumentJpaRepository jpaRepository;
  private final VehicleDocumentPersistenceMapper mapper;

  VehicleDocumentRepositoryAdapter(
      VehicleDocumentJpaRepository jpaRepository, VehicleDocumentPersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<VehicleDocument> findById(VehicleDocumentId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public List<VehicleDocument> findByVehicle(VehicleId vehicleId) {
    return jpaRepository.findByVehicleId(vehicleId.value()).stream().map(mapper::toDomain).toList();
  }

  @Override
  public List<VehicleDocument> findMandatoryByVehicle(VehicleId vehicleId) {
    return jpaRepository.findByVehicleIdAndMandatoryTrue(vehicleId.value()).stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public List<VehicleDocument> findMandatoryExpiringWithin(LocalDate asOf, int days, int limit) {
    return jpaRepository
        .findMandatoryExpiringBy(asOf.plusDays(days), Sort.by("expiresOn"), Limit.of(limit))
        .stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public VehicleDocument save(VehicleDocument document) {
    VehicleDocumentEntity entity =
        jpaRepository
            .findById(document.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, document);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(document));

    return mapper.toDomain(jpaRepository.save(entity));
  }
}
