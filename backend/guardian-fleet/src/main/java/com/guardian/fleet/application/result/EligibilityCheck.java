package com.guardian.fleet.application.result;

/**
 * One named check within a {@link VehicleEligibilityResult}.
 *
 * <p>Reported individually, always — a driver refused at 06:30 needs to know <em>which</em> check
 * failed, not just that eligibility was refused (guardian-docs/04-api/API_STANDARDS.md).
 */
public record EligibilityCheck(String check, boolean passed, String detail, String businessRule) {

  public static EligibilityCheck passed(String check) {
    return new EligibilityCheck(check, true, null, null);
  }

  public static EligibilityCheck failed(String check, String detail, String businessRule) {
    return new EligibilityCheck(check, false, detail, businessRule);
  }
}
