package com.guardian.fleet.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleId;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reads vehicles (feature FLT-001).
 *
 * <p>No explicit tenant filtering appears here: row-level security applies it to every query
 * (ADR-0001). A vehicle in another organization is genuinely not found, which is why this throws
 * {@link ResourceNotFoundException} rather than a permission error.
 */
@Service
public class GetVehicleUseCase {

  private final VehicleRepository vehicleRepository;

  public GetVehicleUseCase(VehicleRepository vehicleRepository) {
    this.vehicleRepository = vehicleRepository;
  }

  @Transactional(readOnly = true)
  public Vehicle byId(VehicleId vehicleId) {
    return vehicleRepository
        .findById(vehicleId)
        .orElseThrow(
            () ->
                new ResourceNotFoundException(
                    ErrorCode.VEHICLE_NOT_FOUND, "Vehicle", vehicleId.value()));
  }

  @Transactional(readOnly = true)
  public List<Vehicle> bySchool(SchoolId schoolId) {
    return vehicleRepository.findBySchool(schoolId);
  }
}
