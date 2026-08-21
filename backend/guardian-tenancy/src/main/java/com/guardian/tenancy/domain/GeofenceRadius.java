package com.guardian.tenancy.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Map;

/**
 * A geofence radius in metres, bounded by platform floors and ceilings.
 *
 * <p>The bounds are not arbitrary (BR-ROUTE-003, BR-CFG-003):
 *
 * <ul>
 *   <li>Below the minimum, GPS drift means arrival is never detected — parents receive no approach
 *       notification and the stop appears skipped.
 *   <li>Above the maximum, geofences overlap and a vehicle registers as arriving at several places
 *       at once, making arrival events meaningless.
 * </ul>
 *
 * <p>A tenant may tune within this window (ADR-0007); they may not leave it (BR-SAFE-007). The same
 * bounds are enforced again as a database check constraint, so no configuration path — present or
 * future — can violate them.
 */
public record GeofenceRadius(int metres) {

  public static final int MIN_METRES = 20;
  public static final int MAX_METRES = 2000;

  public GeofenceRadius {
    if (metres < MIN_METRES || metres > MAX_METRES) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE,
          "BR-CFG-003",
          Map.of("field", "geofenceRadiusM", "min", MIN_METRES, "max", MAX_METRES));
    }
  }

  public static GeofenceRadius ofMetres(int metres) {
    return new GeofenceRadius(metres);
  }
}
