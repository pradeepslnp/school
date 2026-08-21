package com.guardian.tenancy.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/**
 * JPA mapping for {@code organizations}.
 *
 * <p>Never leaves this package — see {@link SchoolEntity}'s documentation for why. Mutable with a
 * no-arg constructor because JPA requires it, unlike the immutable domain type it is mapped to and
 * from by {@link OrganizationPersistenceMapper}.
 */
@Entity
@Table(name = "organizations")
public class OrganizationEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "code", nullable = false, length = 32, updatable = false)
  private String code;

  @Column(name = "name", nullable = false)
  private String name;

  @Column(name = "region_profile_code", nullable = false, length = 32)
  private String regionProfileCode;

  @Column(name = "status", nullable = false, length = 24)
  private String status;

  @Column(name = "contact_email", length = 255)
  private String contactEmail;

  @Column(name = "contact_phone", length = 32)
  private String contactPhone;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  /** Optimistic locking — a concurrent edit fails with 409 rather than silently overwriting. */
  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected OrganizationEntity() {
    // required by JPA
  }

  OrganizationEntity(
      UUID id,
      String code,
      String name,
      String regionProfileCode,
      String status,
      String contactEmail,
      String contactPhone,
      long version) {
    this.id = id;
    this.code = code;
    this.name = name;
    this.regionProfileCode = regionProfileCode;
    this.status = status;
    this.contactEmail = contactEmail;
    this.contactPhone = contactPhone;
    this.version = version;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  void applyMutableState(
      String name,
      String regionProfileCode,
      String status,
      String contactEmail,
      String contactPhone) {
    this.name = name;
    this.regionProfileCode = regionProfileCode;
    this.status = status;
    this.contactEmail = contactEmail;
    this.contactPhone = contactPhone;
    this.updatedAt = Instant.now();
  }

  UUID getId() {
    return id;
  }

  String getCode() {
    return code;
  }

  String getName() {
    return name;
  }

  String getRegionProfileCode() {
    return regionProfileCode;
  }

  String getStatus() {
    return status;
  }

  String getContactEmail() {
    return contactEmail;
  }

  String getContactPhone() {
    return contactPhone;
  }

  long getVersion() {
    return version;
  }
}
