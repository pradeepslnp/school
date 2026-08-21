package com.guardian.fleet.interfaces.rest.dto;

import com.guardian.fleet.application.result.EligibilityCheck;
import com.guardian.fleet.application.result.VehicleEligibilityResult;
import java.util.List;

public record VehicleEligibilityResponse(boolean eligible, List<CheckResponse> checks) {

  public static VehicleEligibilityResponse from(VehicleEligibilityResult result) {
    return new VehicleEligibilityResponse(
        result.eligible(), result.checks().stream().map(CheckResponse::from).toList());
  }

  public record CheckResponse(String check, boolean passed, String detail, String businessRule) {

    static CheckResponse from(EligibilityCheck check) {
      return new CheckResponse(check.check(), check.passed(), check.detail(), check.businessRule());
    }
  }
}
