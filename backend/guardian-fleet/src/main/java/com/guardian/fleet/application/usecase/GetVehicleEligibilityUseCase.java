package com.guardian.fleet.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.fleet.application.port.VehicleDocumentRepository;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.application.result.EligibilityCheck;
import com.guardian.fleet.application.result.VehicleEligibilityResult;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleDocument;
import com.guardian.fleet.domain.VehicleId;
import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Answers "is this vehicle permitted to carry children today?" (feature FLT-003).
 *
 * <p>This is the vehicle half of the trip-start eligibility check
 * (guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md, "Trip-Start Eligibility"). MOD-08
 * Trip Execution combines this with the staff half (BR-STAFF-001/002) before allowing a trip to
 * start; this endpoint exists separately so a fleet manager can see a blocked vehicle before 06:30
 * rather than a driver discovering it at the kerb.
 */
@Service
@BusinessRule({"BR-FLEET-002", "BR-FLEET-001"})
public class GetVehicleEligibilityUseCase {

  private static final String CHECK_VEHICLE_ACTIVE = "VEHICLE_ACTIVE";
  private static final String CHECK_MANDATORY_DOCUMENTS_VALID = "MANDATORY_DOCUMENTS_VALID";

  private final VehicleRepository vehicleRepository;
  private final VehicleDocumentRepository documentRepository;
  private final Clock clock;

  public GetVehicleEligibilityUseCase(
      VehicleRepository vehicleRepository,
      VehicleDocumentRepository documentRepository,
      Clock clock) {
    this.vehicleRepository = vehicleRepository;
    this.documentRepository = documentRepository;
    this.clock = clock;
  }

  @Transactional(readOnly = true)
  public VehicleEligibilityResult execute(VehicleId vehicleId) {
    Vehicle vehicle =
        vehicleRepository
            .findById(vehicleId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.VEHICLE_NOT_FOUND, "Vehicle", vehicleId.value()));

    List<EligibilityCheck> checks = new ArrayList<>();
    boolean eligible = true;

    // BR-FLEET-001: an inactive (maintenance or retired) vehicle cannot be assigned.
    if (vehicle.isActive()) {
      checks.add(EligibilityCheck.passed(CHECK_VEHICLE_ACTIVE));
    } else {
      checks.add(
          EligibilityCheck.failed(
              CHECK_VEHICLE_ACTIVE, "Vehicle status is " + vehicle.status(), "BR-FLEET-001"));
      eligible = false;
    }

    // BR-FLEET-002 🔴: no mandatory document may be expired. Not configurable — tenants choose
    // which documents are mandatory, never whether an expired mandatory one blocks assignment.
    LocalDate today = LocalDate.now(clock);
    List<VehicleDocument> expired =
        documentRepository.findMandatoryByVehicle(vehicleId).stream()
            .filter(document -> document.isExpired(today))
            .toList();

    if (expired.isEmpty()) {
      checks.add(EligibilityCheck.passed(CHECK_MANDATORY_DOCUMENTS_VALID));
    } else {
      VehicleDocument firstExpired = expired.get(0);
      checks.add(
          EligibilityCheck.failed(
              CHECK_MANDATORY_DOCUMENTS_VALID,
              firstExpired.documentType() + " expired " + firstExpired.expiresOn(),
              "BR-FLEET-002"));
      eligible = false;
    }

    return new VehicleEligibilityResult(eligible, checks);
  }
}
