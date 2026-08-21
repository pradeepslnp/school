package com.guardian.staff.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * JPA mapping for {@code duty_assignments}. Never leaves this package — an architecture test fails
 * the build if a controller returns one (guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md).
 */
@Entity
@Table(name = "duty_assignments")
public class DutyAssignmentEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "staff_id", nullable = false, updatable = false)
  private UUID staffId;

  @Column(name = "route_id", nullable = false, updatable = false)
  private UUID routeId;

  @Column(name = "role", nullable = false, length = 24, updatable = false)
  private String role;

  @Column(name = "direction", length = 16, updatable = false)
  private String direction;

  @Column(name = "effective_from", nullable = false, updatable = false)
  private LocalDate effectiveFrom;

  @Column(name = "effective_until")
  private LocalDate effectiveUntil;

  @Column(name = "is_active", nullable = false)
  private boolean active;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected DutyAssignmentEntity() {
    // required by JPA
  }

  DutyAssignmentEntity(
      UUID id,
      UUID tenantId,
      UUID staffId,
      UUID routeId,
      String role,
      String direction,
      LocalDate effectiveFrom,
      LocalDate effectiveUntil,
      boolean active,
      long version) {
    this.id = id;
    this.tenantId = tenantId;
    this.staffId = staffId;
    this.routeId = routeId;
    this.role = role;
    this.direction = direction;
    this.effectiveFrom = effectiveFrom;
    this.effectiveUntil = effectiveUntil;
    this.active = active;
    this.version = version;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  void applyMutableState(LocalDate effectiveUntil, boolean active) {
    this.effectiveUntil = effectiveUntil;
    this.active = active;
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

  UUID getRouteId() {
    return routeId;
  }

  String getRole() {
    return role;
  }

  String getDirection() {
    return direction;
  }

  LocalDate getEffectiveFrom() {
    return effectiveFrom;
  }

  LocalDate getEffectiveUntil() {
    return effectiveUntil;
  }

  boolean isActive() {
    return active;
  }

  long getVersion() {
    return version;
  }
}
