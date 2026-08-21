package com.guardian.fleet.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.domain.VehicleDocument;
import com.guardian.fleet.domain.VehicleDocumentId;
import com.guardian.fleet.domain.VehicleId;
import org.springframework.stereotype.Component;

@Component
class VehicleDocumentPersistenceMapper {

  VehicleDocument toDomain(VehicleDocumentEntity entity) {
    return new VehicleDocument(
        VehicleDocumentId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        VehicleId.of(entity.getVehicleId()),
        entity.getDocumentType(),
        entity.getDocumentNumber(),
        entity.getIssuedOn(),
        entity.getExpiresOn(),
        entity.isMandatory(),
        entity.getFileRef(),
        entity.getVersion());
  }

  VehicleDocumentEntity toEntity(VehicleDocument document) {
    return new VehicleDocumentEntity(
        document.id().value(),
        document.tenantId().value(),
        document.vehicleId().value(),
        document.documentType(),
        document.documentNumber().orElse(null),
        document.issuedOn().orElse(null),
        document.expiresOn(),
        document.mandatory(),
        document.fileRef().orElse(null),
        document.version());
  }

  void applyTo(VehicleDocumentEntity managed, VehicleDocument document) {
    managed.applyMutableState(
        document.documentNumber().orElse(null),
        document.issuedOn().orElse(null),
        document.expiresOn(),
        document.mandatory(),
        document.fileRef().orElse(null));
  }
}
