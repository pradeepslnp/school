package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.staff.application.port.StaffCredentialRepository;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.application.result.EligibilityCheck;
import com.guardian.staff.application.result.StaffEligibilityResult;
import com.guardian.staff.domain.StaffCredential;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.TransportStaff;
import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Answers "is this driver or attendant permitted to be on duty today?" (feature STF-003).
 *
 * <p>This is the staff half of the trip-start eligibility check
 * (guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md, "Trip-Start Eligibility"); MOD-08
 * Trip Execution combines it with the vehicle half ({@code GetVehicleEligibilityUseCase} in
 * guardian-fleet) before allowing a trip to start.
 *
 * <p>The mandatory-credentials check here proves only the expiry half of BR-STAFF-001 — that no
 * mandatory credential has lapsed. The other half, "of the required class," is a comparison against
 * a specific vehicle's type, and this endpoint has no vehicle in scope. {@link
 * StaffCredential#coversClass(String)} exists for MOD-08 to call once it has both a staff member
 * and a vehicle to compare; this use case does not call it and does not claim to.
 */
@Service
@BusinessRule("BR-STAFF-002")
public class GetStaffEligibilityUseCase {

  private static final String CHECK_STAFF_VERIFIED = "STAFF_VERIFIED";
  private static final String CHECK_MANDATORY_CREDENTIALS_VALID = "MANDATORY_CREDENTIALS_VALID";

  private final TransportStaffRepository staffRepository;
  private final StaffCredentialRepository credentialRepository;
  private final Clock clock;

  public GetStaffEligibilityUseCase(
      TransportStaffRepository staffRepository,
      StaffCredentialRepository credentialRepository,
      Clock clock) {
    this.staffRepository = staffRepository;
    this.credentialRepository = credentialRepository;
    this.clock = clock;
  }

  @Transactional(readOnly = true)
  public StaffEligibilityResult execute(StaffId staffId) {
    TransportStaff staff =
        staffRepository
            .findById(staffId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "TransportStaff", staffId.value()));

    List<EligibilityCheck> checks = new ArrayList<>();
    boolean eligible = true;

    LocalDate today = LocalDate.now(clock);

    // BR-STAFF-002 🔴: verification must be current, not merely once-granted.
    if (staff.isVerifiedAsOf(today)) {
      checks.add(EligibilityCheck.passed(CHECK_STAFF_VERIFIED));
    } else {
      checks.add(
          EligibilityCheck.failed(
              CHECK_STAFF_VERIFIED,
              "Verification status is " + staff.verificationStatus(),
              "BR-STAFF-002"));
      eligible = false;
    }

    // BR-STAFF-001 🔴 (expiry half only — see class comment): no mandatory credential may be
    // expired.
    List<StaffCredential> expired =
        credentialRepository.findMandatoryByStaff(staffId).stream()
            .filter(credential -> credential.isExpired(today))
            .toList();

    if (expired.isEmpty()) {
      checks.add(EligibilityCheck.passed(CHECK_MANDATORY_CREDENTIALS_VALID));
    } else {
      StaffCredential firstExpired = expired.get(0);
      checks.add(
          EligibilityCheck.failed(
              CHECK_MANDATORY_CREDENTIALS_VALID,
              firstExpired.credentialType() + " expired " + firstExpired.expiresOn(),
              "BR-STAFF-001"));
      eligible = false;
    }

    return new StaffEligibilityResult(eligible, checks);
  }
}
