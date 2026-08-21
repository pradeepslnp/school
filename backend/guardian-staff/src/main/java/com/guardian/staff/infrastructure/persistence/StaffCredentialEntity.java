package com.guardian.staff.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "staff_credentials")
public class StaffCredentialEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "staff_id", nullable = false, updatable = false)
  private UUID staffId;

  @Column(name = "credential_type", nullable = false, length = 48, updatable = false)
  private String credentialType;

  @Column(name = "credential_number", length = 128)
  private String credentialNumber;

  @Column(name = "credential_class", length = 32)
  private String credentialClass;

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

  protected StaffCredentialEntity() {
    // required by JPA
  }

  StaffCredentialEntity(
      UUID id,
      UUID tenantId,
      UUID staffId,
      String credentialType,
      String credentialNumber,
      String credentialClass,
      LocalDate issuedOn,
      LocalDate expiresOn,
      boolean mandatory,
      String fileRef,
      long version) {
    this.id = id;
    this.tenantId = tenantId;
    this.staffId = staffId;
    this.credentialType = credentialType;
    this.credentialNumber = credentialNumber;
    this.credentialClass = credentialClass;
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
      String credentialNumber,
      String credentialClass,
      LocalDate issuedOn,
      LocalDate expiresOn,
      boolean mandatory,
      String fileRef) {
    this.credentialNumber = credentialNumber;
    this.credentialClass = credentialClass;
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

  UUID getStaffId() {
    return staffId;
  }

  String getCredentialType() {
    return credentialType;
  }

  String getCredentialNumber() {
    return credentialNumber;
  }

  String getCredentialClass() {
    return credentialClass;
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
