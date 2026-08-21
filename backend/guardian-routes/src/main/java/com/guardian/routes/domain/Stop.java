package com.guardian.routes.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.time.LocalTime;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * One point on a {@link Route} (feature RTE-001).
 *
 * <p>{@code name} appears verbatim in parent notifications ("Boarded at Green Park") — parent-
 * facing copy, not an internal label (MOD-07-routes.md).
 *
 * <p>The geofence bound (20–500 m) is BR-ROUTE-003's floor and ceiling, not the wider 20–2000 m the
 * database CHECK constraint allows — the constraint is the outer safety net; this is the documented
 * business rule, and the narrower of the two is authoritative for a new stop.
 */
public final class Stop {

  private static final int MIN_GEOFENCE_RADIUS_M = 20;
  private static final int MAX_GEOFENCE_RADIUS_M = 500;

  private final StopId id;
  private final int sequenceNo;
  private final String name;
  private final double latitude;
  private final double longitude;
  private final int geofenceRadiusM;
  private final LocalTime scheduledPickupTime;
  private final LocalTime scheduledDropTime;
  private final String landmark;

  public Stop(
      StopId id,
      int sequenceNo,
      String name,
      double latitude,
      double longitude,
      int geofenceRadiusM,
      LocalTime scheduledPickupTime,
      LocalTime scheduledDropTime,
      String landmark) {
    this.id = Objects.requireNonNull(id, "id");
    if (sequenceNo <= 0) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE, "BR-ROUTE-001", Map.of("field", "sequenceNo"));
    }
    this.sequenceNo = sequenceNo;
    this.name = requireText(name, "name");
    if (latitude < -90 || latitude > 90) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE, "BR-ROUTE-001", Map.of("field", "latitude"));
    }
    this.latitude = latitude;
    if (longitude < -180 || longitude > 180) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE, "BR-ROUTE-001", Map.of("field", "longitude"));
    }
    this.longitude = longitude;
    if (geofenceRadiusM < MIN_GEOFENCE_RADIUS_M || geofenceRadiusM > MAX_GEOFENCE_RADIUS_M) {
      throw new BusinessRuleViolationException(
          ErrorCode.ROUTE_GEOFENCE_OUT_OF_BOUNDS,
          "BR-ROUTE-003",
          Map.of("geofenceRadiusM", geofenceRadiusM));
    }
    this.geofenceRadiusM = geofenceRadiusM;
    this.scheduledPickupTime = scheduledPickupTime;
    this.scheduledDropTime = scheduledDropTime;
    this.landmark = landmark;
  }

  public StopId id() {
    return id;
  }

  public int sequenceNo() {
    return sequenceNo;
  }

  public String name() {
    return name;
  }

  public double latitude() {
    return latitude;
  }

  public double longitude() {
    return longitude;
  }

  public int geofenceRadiusM() {
    return geofenceRadiusM;
  }

  public Optional<LocalTime> scheduledPickupTime() {
    return Optional.ofNullable(scheduledPickupTime);
  }

  public Optional<LocalTime> scheduledDropTime() {
    return Optional.ofNullable(scheduledDropTime);
  }

  public Optional<String> landmark() {
    return Optional.ofNullable(landmark);
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
}
