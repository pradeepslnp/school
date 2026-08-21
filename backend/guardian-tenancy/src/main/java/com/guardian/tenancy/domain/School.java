package com.guardian.tenancy.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.time.ZoneId;
import java.util.Map;
import java.util.Objects;

/**
 * A school within an organization.
 *
 * <p>Operational data — students, staff, vehicles, routes, trips — belongs to a school rather than
 * directly to an organization (ADR-0002).
 *
 * <p>Immutable: state changes return new instances. Contains no framework annotations of any kind;
 * an architecture test fails the build if Spring, JPA, or Jackson types reach this package
 * (ENGINEERING_PRINCIPLES.md §1).
 */
public final class School {

  private final SchoolId id;
  private final TenantId tenantId;
  private final OrganizationId organizationId;
  private final SchoolCode code;
  private final String name;
  private final ZoneId timezone;
  private final Coordinates location;
  private final GeofenceRadius geofenceRadius;
  private final SchoolStatus status;
  private final long version;

  public School(
      SchoolId id,
      TenantId tenantId,
      OrganizationId organizationId,
      SchoolCode code,
      String name,
      ZoneId timezone,
      Coordinates location,
      GeofenceRadius geofenceRadius,
      SchoolStatus status,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.organizationId = Objects.requireNonNull(organizationId, "organizationId");
    this.code = Objects.requireNonNull(code, "code");
    this.name = requireText(name, "name");
    // Not defaulted: every displayed time depends on it (BR-CFG-006), and defaulting to
    // server time would be silently wrong for any school outside the server's zone.
    this.timezone = Objects.requireNonNull(timezone, "timezone");
    this.location = Objects.requireNonNull(location, "location");
    this.geofenceRadius = Objects.requireNonNull(geofenceRadius, "geofenceRadius");
    this.status = Objects.requireNonNull(status, "status");
    this.version = version;
  }

  /** Creates a new, active school. */
  public static School create(
      TenantId tenantId,
      OrganizationId organizationId,
      SchoolCode code,
      String name,
      ZoneId timezone,
      Coordinates location,
      GeofenceRadius geofenceRadius) {
    return new School(
        SchoolId.generate(),
        tenantId,
        organizationId,
        code,
        name,
        timezone,
        location,
        geofenceRadius,
        SchoolStatus.ACTIVE,
        0L);
  }

  /**
   * Moving a school between organizations is refused (BR-TEN-003).
   *
   * <p>The organization is the tenant, so a move would relocate every student, vehicle, and safety
   * record across an isolation boundary. There is no correct implementation of this operation.
   */
  public School assertBelongsTo(OrganizationId expected) {
    if (!organizationId.equals(expected)) {
      throw new BusinessRuleViolationException(
          ErrorCode.SCHOOL_CANNOT_CHANGE_ORGANIZATION,
          "BR-TEN-003",
          Map.of("schoolId", id.toString()));
    }
    return this;
  }

  public School rename(String newName) {
    return new School(
        id,
        tenantId,
        organizationId,
        code,
        requireText(newName, "name"),
        timezone,
        location,
        geofenceRadius,
        status,
        version);
  }

  /**
   * Corrects the school's timezone.
   *
   * <p>A separate method from {@link #relocate}, not a parameter added to it: a wrong timezone is a
   * data-entry mistake, whereas a location change describes the school actually moving — conflating
   * the two would make an audit record ambiguous about which happened.
   */
  public School reschedule(ZoneId newTimezone) {
    return new School(
        id,
        tenantId,
        organizationId,
        code,
        name,
        Objects.requireNonNull(newTimezone, "timezone"),
        location,
        geofenceRadius,
        status,
        version);
  }

  public School relocate(Coordinates newLocation, GeofenceRadius newRadius) {
    return new School(
        id,
        tenantId,
        organizationId,
        code,
        name,
        timezone,
        Objects.requireNonNull(newLocation, "newLocation"),
        Objects.requireNonNull(newRadius, "newRadius"),
        status,
        version);
  }

  public School deactivate() {
    return new School(
        id,
        tenantId,
        organizationId,
        code,
        name,
        timezone,
        location,
        geofenceRadius,
        SchoolStatus.INACTIVE,
        version);
  }

  public boolean isActive() {
    return status == SchoolStatus.ACTIVE;
  }

  private static String requireText(String value, String field) {
    Objects.requireNonNull(value, field);
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-TEN-002", Map.of("field", field));
    }
    return trimmed;
  }

  public SchoolId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public OrganizationId organizationId() {
    return organizationId;
  }

  public SchoolCode code() {
    return code;
  }

  public String name() {
    return name;
  }

  public ZoneId timezone() {
    return timezone;
  }

  public Coordinates location() {
    return location;
  }

  public GeofenceRadius geofenceRadius() {
    return geofenceRadius;
  }

  public SchoolStatus status() {
    return status;
  }

  public long version() {
    return version;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof School school && id.equals(school.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "School[" + id + ", " + code + "]";
  }
}
