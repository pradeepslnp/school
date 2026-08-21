package com.guardian.fleet.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "vehicle_documents")
public class VehicleDocumentEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "vehicle_id", nullable = false, updatable = false)
  private UUID vehicleId;

  @Column(name = "document_type", nullable = false, length = 48, updatable = false)
  private String documentType;

  @Column(name = "document_number", length = 128)
  private String documentNumber;

  @Column(name = "issued_on")
  private LocalDate issuedOn;

  @Column(name = "expires_on", nullable = false)
  private LocalDate expiresOn;

  @Column(name = "is_mandatory", nullable = false)
  private boolean mandatory;

  @Column(name = "file_ref")
  private String fileRef;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected VehicleDocumentEntity() {
    // required by JPA
  }

  VehicleDocumentEntity(
      UUID id,
      UUID tenantId,
      UUID vehicleId,
      String documentType,
      String documentNumber,
      LocalDate issuedOn,
      LocalDate expiresOn,
      boolean mandatory,
      String fileRef,
      long version) {
    this.id = id;
    this.tenantId = tenantId;
    this.vehicleId = vehicleId;
    this.documentType = documentType;
    this.documentNumber = documentNumber;
    this.issuedOn = issuedOn;
    this.expiresOn = expiresOn;
    this.mandatory = mandatory;
    this.fileRef = fileRef;
    this.version = version;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  void applyMutableState(
      String documentNumber,
      LocalDate issuedOn,
      LocalDate expiresOn,
      boolean mandatory,
      String fileRef) {
    this.documentNumber = documentNumber;
    this.issuedOn = issuedOn;
    this.expiresOn = expiresOn;
    this.mandatory = mandatory;
    this.fileRef = fileRef;
    this.updatedAt = Instant.now();
  }

  UUID getId() {
    return id;
  }

  UUID getTenantId() {
    return tenantId;
  }

  UUID getVehicleId() {
    return vehicleId;
  }

  String getDocumentType() {
    return documentType;
  }

  String getDocumentNumber() {
    return documentNumber;
  }

  LocalDate getIssuedOn() {
    return issuedOn;
  }

  LocalDate getExpiresOn() {
    return expiresOn;
  }

  boolean isMandatory() {
    return mandatory;
  }

  String getFileRef() {
    return fileRef;
  }

  long getVersion() {
    return version;
  }
}
