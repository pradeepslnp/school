package com.guardian.fleet.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/**
 * JPA mapping for {@code vehicles}. Never leaves this package — an architecture test fails the
 * build if a controller returns one (guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md).
 */
@Entity
@Table(name = "vehicles")
public class VehicleEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "school_id", nullable = false, updatable = false)
  private UUID schoolId;

  @Column(name = "registration_no", nullable = false, length = 32, updatable = false)
  private String registrationNo;

  @Column(name = "display_name", nullable = false)
  private String displayName;

  @Column(name = "vehicle_type", nullable = false, length = 24, updatable = false)
  private String vehicleType;

  @Column(name = "seating_capacity", nullable = false)
  private Integer seatingCapacity;

  @Column(name = "vendor_name")
  private String vendorName;

  @Column(name = "status", nullable = false, length = 24)
  private String status;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected VehicleEntity() {
    // required by JPA
  }

  VehicleEntity(
      UUID id,
      UUID tenantId,
      UUID schoolId,
      String registrationNo,
      String displayName,
      String vehicleType,
      Integer seatingCapacity,
      String vendorName,
      String status,
      long version) {
    this.id = id;
    this.tenantId = tenantId;
    this.schoolId = schoolId;
    this.registrationNo = registrationNo;
    this.displayName = displayName;
    this.vehicleType = vehicleType;
    this.seatingCapacity = seatingCapacity;
    this.vendorName = vendorName;
    this.status = status;
    this.version = version;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  void applyMutableState(
      String displayName, Integer seatingCapacity, String vendorName, String status) {
    this.displayName = displayName;
    this.seatingCapacity = seatingCapacity;
    this.vendorName = vendorName;
    this.status = status;
    this.updatedAt = Instant.now();
  }

  UUID getId() {
    return id;
  }

  UUID getTenantId() {
    return tenantId;
  }

  UUID getSchoolId() {
    return schoolId;
  }

  String getRegistrationNo() {
    return registrationNo;
  }

  String getDisplayName() {
    return displayName;
  }

  String getVehicleType() {
    return vehicleType;
  }

  Integer getSeatingCapacity() {
    return seatingCapacity;
  }

  String getVendorName() {
    return vendorName;
  }

  String getStatus() {
    return status;
  }

  long getVersion() {
    return version;
  }
}
