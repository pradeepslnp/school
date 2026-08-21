package com.guardian.tenancy.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * JPA mapping for {@code schools}.
 *
 * <p>Never leaves this package. An architecture test fails the build if a controller returns one,
 * and mapping to and from {@link com.guardian.tenancy.domain.School} is explicit ({@link
 * SchoolPersistenceMapper}).
 *
 * <p>The separation costs boilerplate and buys independence: safety records outlive ORM choices,
 * and retention, partitioning, and archival changes must not ripple into domain rules
 * (ENGINEERING_PRINCIPLES.md §4).
 *
 * <p>Mutable with a no-arg constructor because JPA requires it — one more reason to keep it out of
 * the domain, where every object is immutable.
 */
@Entity
@Table(name = "schools")
public class SchoolEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "organization_id", nullable = false, updatable = false)
  private UUID organizationId;

  @Column(name = "code", nullable = false, length = 32, updatable = false)
  private String code;

  @Column(name = "name", nullable = false)
  private String name;

  @Column(name = "timezone", nullable = false, length = 64)
  private String timezone;

  @Column(name = "latitude", nullable = false, precision = 9, scale = 6)
  private BigDecimal latitude;

  @Column(name = "longitude", nullable = false, precision = 9, scale = 6)
  private BigDecimal longitude;

  @Column(name = "geofence_radius_m", nullable = false)
  private Integer geofenceRadiusM;

  @Column(name = "status", nullable = false, length = 24)
  private String status;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  /** Optimistic locking — a concurrent edit fails with 409 rather than silently overwriting. */
  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected SchoolEntity() {
    // required by JPA
  }

  SchoolEntity(
      UUID id,
      UUID tenantId,
      UUID organizationId,
      String code,
      String name,
      String timezone,
      BigDecimal latitude,
      BigDecimal longitude,
      Integer geofenceRadiusM,
      String status,
      long version) {
    this.id = id;
    this.tenantId = tenantId;
    this.organizationId = organizationId;
    this.code = code;
    this.name = name;
    this.timezone = timezone;
    this.latitude = latitude;
    this.longitude = longitude;
    this.geofenceRadiusM = geofenceRadiusM;
    this.status = status;
    this.version = version;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  void applyMutableState(
      String name,
      BigDecimal latitude,
      BigDecimal longitude,
      Integer geofenceRadiusM,
      String status) {
    this.name = name;
    this.latitude = latitude;
    this.longitude = longitude;
    this.geofenceRadiusM = geofenceRadiusM;
    this.status = status;
    this.updatedAt = Instant.now();
  }

  UUID getId() {
    return id;
  }

  UUID getTenantId() {
    return tenantId;
  }

  UUID getOrganizationId() {
    return organizationId;
  }

  String getCode() {
    return code;
  }

  String getName() {
    return name;
  }

  String getTimezone() {
    return timezone;
  }

  BigDecimal getLatitude() {
    return latitude;
  }

  BigDecimal getLongitude() {
    return longitude;
  }

  Integer getGeofenceRadiusM() {
    return geofenceRadiusM;
  }

  String getStatus() {
    return status;
  }

  long getVersion() {
    return version;
  }
}
