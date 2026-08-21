package com.guardian.fleet.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Map;

/**
 * A vehicle's seating capacity (BR-FLEET-005).
 *
 * <p>Recorded here so trip assignment can compare a manifest against it. The warning-and-override
 * behaviour when a manifest exceeds capacity is enforced at assignment time in MOD-08 Trip
 * Execution, not here — this type only guarantees the number itself is meaningful.
 */
public record SeatingCapacity(int seats) {

  public SeatingCapacity {
    if (seats <= 0) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE,
          "BR-FLEET-005",
          Map.of("field", "seatingCapacity", "min", 1));
    }
  }

  public static SeatingCapacity of(int seats) {
    return new SeatingCapacity(seats);
  }
}
