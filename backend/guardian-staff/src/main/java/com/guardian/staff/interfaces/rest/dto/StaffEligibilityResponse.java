package com.guardian.staff.interfaces.rest.dto;

import com.guardian.staff.application.result.EligibilityCheck;
import com.guardian.staff.application.result.StaffEligibilityResult;
import java.util.List;

public record StaffEligibilityResponse(boolean eligible, List<CheckResponse> checks) {

  public static StaffEligibilityResponse from(StaffEligibilityResult result) {
    return new StaffEligibilityResponse(
        result.eligible(), result.checks().stream().map(CheckResponse::from).toList());
  }

  public record CheckResponse(String check, boolean passed, String detail, String businessRule) {

    static CheckResponse from(EligibilityCheck check) {
      return new CheckResponse(check.check(), check.passed(), check.detail(), check.businessRule());
    }
  }
}
