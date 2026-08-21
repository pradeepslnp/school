package com.guardian.routes.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * A standing pickup/drop path a vehicle runs for a school (feature RTE-001).
 *
 * <p>Immutable: state changes return new instances. Contains no framework annotations of any kind —
 * an architecture test fails the build if Spring, JPA, or Jackson types reach this package
 * (guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md).
 *
 * <p>A route's stops are not held here. They live in their own table ({@code stops}), replaced as a
 * full ordered list rather than edited piecemeal (guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md
 * §Routes) — partial stop edits invite sequence gaps and ordering bugs. This aggregate is only the
 * route's own identity and its default vehicle.
 */
public final class Route {

  private final RouteId id;
  private final TenantId tenantId;
  private final SchoolId schoolId;
  private final String code;
  private final String name;
  private final VehicleId defaultVehicleId;
  private final boolean active;
  private final long version;

  public Route(
      RouteId id,
      TenantId tenantId,
      SchoolId schoolId,
      String code,
      String name,
      VehicleId defaultVehicleId,
      boolean active,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.schoolId = Objects.requireNonNull(schoolId, "schoolId");
    this.code = requireText(code, "code");
    this.name = requireText(name, "name");
    this.defaultVehicleId = defaultVehicleId;
    this.active = active;
    this.version = version;
  }

  /** Creates a new, active route (feature RTE-001). */
  public static Route create(
      TenantId tenantId, SchoolId schoolId, String code, String name, VehicleId defaultVehicleId) {
    return new Route(
        RouteId.generate(), tenantId, schoolId, code, name, defaultVehicleId, true, 0L);
  }

  public RouteId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public SchoolId schoolId() {
    return schoolId;
  }

  public String code() {
    return code;
  }

  public String name() {
    return name;
  }

  public Optional<VehicleId> defaultVehicleId() {
    return Optional.ofNullable(defaultVehicleId);
  }

  public boolean active() {
    return active;
  }

  public long version() {
    return version;
  }

  private static String requireText(String value, String field) {
    Objects.requireNonNull(value, field);
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-ROUTE-001", Map.of("field", field));
    }
    return trimmed;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof Route route && id.equals(route.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "Route[" + id + ", " + code + "]";
  }
}
