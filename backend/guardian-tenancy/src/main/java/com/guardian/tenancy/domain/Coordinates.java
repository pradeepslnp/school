package com.guardian.tenancy.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;
import java.util.Objects;

/**
 * A geographic point.
 *
 * <p>{@link BigDecimal} rather than {@code double}: coordinates are compared for equality and
 * persisted as {@code NUMERIC(9,6)}, and binary floating point makes both unreliable
 * (guardian-docs/03-database/CONVENTIONS.md).
 *
 * <p>Six decimal places is roughly 0.1 m — far beyond what consumer GPS delivers, and enough that
 * rounding never affects a geofence decision.
 */
public record Coordinates(BigDecimal latitude, BigDecimal longitude) {

  private static final int SCALE = 6;
  private static final BigDecimal MIN_LATITUDE = new BigDecimal("-90");
  private static final BigDecimal MAX_LATITUDE = new BigDecimal("90");
  private static final BigDecimal MIN_LONGITUDE = new BigDecimal("-180");
  private static final BigDecimal MAX_LONGITUDE = new BigDecimal("180");

  public Coordinates {
    Objects.requireNonNull(latitude, "latitude");
    Objects.requireNonNull(longitude, "longitude");
    latitude = latitude.setScale(SCALE, RoundingMode.HALF_UP);
    longitude = longitude.setScale(SCALE, RoundingMode.HALF_UP);
    requireInRange(latitude, MIN_LATITUDE, MAX_LATITUDE, "latitude");
    requireInRange(longitude, MIN_LONGITUDE, MAX_LONGITUDE, "longitude");
  }

  public static Coordinates of(String latitude, String longitude) {
    return new Coordinates(new BigDecimal(latitude), new BigDecimal(longitude));
  }

  private static void requireInRange(
      BigDecimal value, BigDecimal min, BigDecimal max, String field) {
    if (value.compareTo(min) < 0 || value.compareTo(max) > 0) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE,
          "BR-TRACK-004",
          Map.of("field", field, "min", min, "max", max));
    }
  }
}
