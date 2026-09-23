package com.guardian.routes.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/**
 * JPA mapping for {@code routes}. Never leaves this package — an architecture test fails the build
 * if a controller returns one (guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md).
 */
@Entity
@Table(name = "routes")
public class RouteEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "school_id", nullable = false, updatable = false)
  private UUID schoolId;

  @Column(name = "code", nullable = false, length = 32, updatable = false)
  private String code;

  @Column(name = "name", nullable = false)
  private String name;

  @Column(name = "default_vehicle_id")
  private UUID defaultVehicleId;

  @Column(name = "operating_days", nullable = false, length = 27)
  private String operatingDays;

  @Column(name = "is_active", nullable = false)
  private boolean active;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected RouteEntity() {
    // required by JPA
  }

  RouteEntity(
      UUID id,
      UUID tenantId,
      UUID schoolId,
      String code,
      String name,
      UUID defaultVehicleId,
      String operatingDays,
      boolean active,
      long version) {
    this.id = id;
    this.tenantId = tenantId;
    this.schoolId = schoolId;
    this.code = code;
    this.name = name;
    this.defaultVehicleId = defaultVehicleId;
    this.operatingDays = operatingDays;
    this.active = active;
    this.version = version;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  void applyMutableState(
      String name, UUID defaultVehicleId, String operatingDays, boolean active) {
    this.name = name;
    this.defaultVehicleId = defaultVehicleId;
    this.operatingDays = operatingDays;
    this.active = active;
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

  String getCode() {
    return code;
  }

  String getName() {
    return name;
  }

  UUID getDefaultVehicleId() {
    return defaultVehicleId;
  }

  String getOperatingDays() {
    return operatingDays;
  }

  boolean isActive() {
    return active;
  }

  long getVersion() {
    return version;
  }
}
