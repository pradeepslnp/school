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
 * <p>{@link OperatingDays} <em>is</em> held here, unlike stops: it is one small value that belongs
 * to the route itself, and it is the input MOD-08 reads to decide whether a run should exist on a
 * given date (BR-TRIP-011). Validating it here is what stops a typo like {@code TEU} reaching the
 * column, where its only symptom would be a route that silently stops running on Tuesdays.
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
  private final OperatingDays operatingDays;
  private final boolean active;
  private final long version;

  public Route(
      RouteId id,
      TenantId tenantId,
      SchoolId schoolId,
      String code,
      String name,
      VehicleId defaultVehicleId,
      OperatingDays operatingDays,
      boolean active,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.schoolId = Objects.requireNonNull(schoolId, "schoolId");
    this.code = requireText(code, "code");
    this.name = requireText(name, "name");
    this.defaultVehicleId = defaultVehicleId;
    this.operatingDays = Objects.requireNonNull(operatingDays, "operatingDays");
    this.active = active;
    this.version = version;
  }

  /**
   * Creates a new, active route (feature RTE-001).
   *
   * @param operatingDays null defaults to the five-day school week, matching the column default so
   *     a route created through the API and one created before V22 agree.
   */
  public static Route create(
      TenantId tenantId,
      SchoolId schoolId,
      String code,
      String name,
      VehicleId defaultVehicleId,
      OperatingDays operatingDays) {
    return new Route(
        RouteId.generate(),
        tenantId,
        schoolId,
        code,
        name,
        defaultVehicleId,
        operatingDays == null ? OperatingDays.schoolWeek() : operatingDays,
        true,
        0L);
  }

  /**
   * Returns this route with the operator's edits applied (feature RTE-001).
   *
   * <p>{@code code} and {@code schoolId} are not editable: a route code appears on printed lists,
   * in parents' messages and in every trip generated under it, so changing one silently
   * re-labels history. Retiring the route and creating its replacement keeps that history true.
   *
   * <p>Each argument being null means "leave unchanged", which is what makes this usable from a
   * PATCH without a second representation of the same object.
   *
   * <p><strong>{@code active} is not editable here, deliberately.</strong> BR-ROUTE-007 makes
   * deactivating a route conditional on every student assigned to it being reassigned or
   * explicitly released, and that check is not built. A setter that flipped the flag without it
   * would silently strand children on a route that no longer generates trips — the failure would
   * appear as a bus that simply never came. Deactivation ships with the rule that guards it.
   */
  public Route withEdits(
      String newName, VehicleId newDefaultVehicleId, OperatingDays newOperatingDays) {
    return new Route(
        id,
        tenantId,
        schoolId,
        code,
        newName == null ? name : newName,
        newDefaultVehicleId == null ? defaultVehicleId : newDefaultVehicleId,
        newOperatingDays == null ? operatingDays : newOperatingDays,
        active,
        version);
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

  public OperatingDays operatingDays() {
    return operatingDays;
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
