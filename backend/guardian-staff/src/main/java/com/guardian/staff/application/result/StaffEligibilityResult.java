package com.guardian.staff.application.result;

import java.util.List;

/**
 * Answer to "is this staff member permitted to be on duty today?" (feature STF-003).
 *
 * <p>Lets a fleet manager see why a driver or attendant is blocked before 06:30, rather than
 * discovering it when a trip cannot start (guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md). This is
 * the staff half of the trip-start eligibility check
 * (guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md, "Trip-Start Eligibility"); MOD-08
 * Trip Execution combines it with the vehicle half ({@code GetVehicleEligibilityUseCase} in
 * guardian-fleet) before allowing a trip to start.
 */
public record StaffEligibilityResult(boolean eligible, List<EligibilityCheck> checks) {

  public StaffEligibilityResult {
    checks = List.copyOf(checks);
  }
}
