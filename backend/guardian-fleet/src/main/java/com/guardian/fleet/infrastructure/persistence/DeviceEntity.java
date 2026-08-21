package com.guardian.fleet.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "devices")
public class DeviceEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "vehicle_id")
  private UUID vehicleId;

  @Column(name = "device_identifier", nullable = false, length = 128, updatable = false)
  private String deviceIdentifier;

  @Column(name = "vendor_code", nullable = false, length = 48, updatable = false)
  private String vendorCode;

  @Column(name = "credential_hash", nullable = false)
  private String credentialHash;

  @Column(name = "last_seen_at")
  private Instant lastSeenAt;

  @Column(name = "is_active", nullable = false)
  private boolean active;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected DeviceEntity() {
    // required by JPA
  }

  DeviceEntity(
      UUID id,
      UUID tenantId,
      UUID vehicleId,
      String deviceIdentifier,
      String vendorCode,
      String credentialHash,
      Instant lastSeenAt,
      boolean active,
      long version) {
    this.id = id;
    this.tenantId = tenantId;
    this.vehicleId = vehicleId;
    this.deviceIdentifier = deviceIdentifier;
    this.vendorCode = vendorCode;
    this.credentialHash = credentialHash;
    this.lastSeenAt = lastSeenAt;
    this.active = active;
    this.version = version;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  void applyMutableState(UUID vehicleId, Instant lastSeenAt, boolean active) {
    this.vehicleId = vehicleId;
    this.lastSeenAt = lastSeenAt;
    this.active = active;
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

  String getDeviceIdentifier() {
    return deviceIdentifier;
  }

  String getVendorCode() {
    return vendorCode;
  }

  String getCredentialHash() {
    return credentialHash;
  }

  Instant getLastSeenAt() {
    return lastSeenAt;
  }

  boolean isActive() {
    return active;
  }

  long getVersion() {
    return version;
  }
}
