package com.guardian.fleet.application.result;

import java.util.List;

/**
 * Answer to "is this vehicle permitted to carry children today?" (feature FLT-003).
 *
 * <p>Lets a fleet manager see why a vehicle is blocked before 06:30, rather than discovering it
 * when a driver cannot start (guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md).
 */
public record VehicleEligibilityResult(boolean eligible, List<EligibilityCheck> checks) {

  public VehicleEligibilityResult {
    checks = List.copyOf(checks);
  }
}
