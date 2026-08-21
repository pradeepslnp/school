package com.guardian.fleet.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.fleet.application.command.CreateVehicleCommand;
import com.guardian.fleet.application.command.UpdateVehicleCommand;
import com.guardian.fleet.application.usecase.CreateVehicleUseCase;
import com.guardian.fleet.application.usecase.GetVehicleEligibilityUseCase;
import com.guardian.fleet.application.usecase.GetVehicleUseCase;
import com.guardian.fleet.application.usecase.UpdateVehicleUseCase;
import com.guardian.fleet.domain.RegistrationNo;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.SeatingCapacity;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleId;
import com.guardian.fleet.domain.VehicleType;
import com.guardian.fleet.interfaces.rest.dto.CreateVehicleRequest;
import com.guardian.fleet.interfaces.rest.dto.UpdateVehicleRequest;
import com.guardian.fleet.interfaces.rest.dto.VehicleEligibilityResponse;
import com.guardian.fleet.interfaces.rest.dto.VehicleResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Vehicle endpoints (feature FLT-001, FLT-003). See guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md.
 *
 * <p>Every method declares a permission from the permission matrix — an architecture test fails the
 * build for any endpoint that does not (BR-IAM-002). This layer only translates: parse the wire
 * format into domain types, call one use case, map the result back.
 */
@RestController
@RequestMapping("/api/v1/vehicles")
public class VehicleController {

  private final CreateVehicleUseCase createVehicle;
  private final GetVehicleUseCase getVehicle;
  private final UpdateVehicleUseCase updateVehicle;
  private final GetVehicleEligibilityUseCase getVehicleEligibility;

  public VehicleController(
      CreateVehicleUseCase createVehicle,
      GetVehicleUseCase getVehicle,
      UpdateVehicleUseCase updateVehicle,
      GetVehicleEligibilityUseCase getVehicleEligibility) {
    this.createVehicle = createVehicle;
    this.getVehicle = getVehicle;
    this.updateVehicle = updateVehicle;
    this.getVehicleEligibility = getVehicleEligibility;
  }

  @PostMapping
  @RequiresPermission("PERM-VEHICLE-MANAGE")
  public ResponseEntity<VehicleResponse> create(
      @Valid @RequestBody CreateVehicleRequest request, CurrentActor actor) {

    CreateVehicleCommand command =
        new CreateVehicleCommand(
            SchoolId.of(request.schoolId()),
            RegistrationNo.of(request.registrationNo()),
            request.displayName(),
            VehicleType.valueOf(request.vehicleType()),
            SeatingCapacity.of(request.seatingCapacity()),
            request.vendorName(),
            actor.userId(),
            actor.role());

    Vehicle created = createVehicle.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/vehicles/" + created.id()))
        .body(VehicleResponse.from(created));
  }

  @GetMapping("/{vehicleId}")
  @RequiresPermission("PERM-VEHICLE-VIEW")
  public VehicleResponse getById(@PathVariable UUID vehicleId) {
    return VehicleResponse.from(getVehicle.byId(VehicleId.of(vehicleId)));
  }

  @GetMapping
  @RequiresPermission("PERM-VEHICLE-VIEW")
  public List<VehicleResponse> listBySchool(@RequestParam UUID schoolId) {
    return getVehicle.bySchool(SchoolId.of(schoolId)).stream().map(VehicleResponse::from).toList();
  }

  @PatchMapping("/{vehicleId}")
  @RequiresPermission("PERM-VEHICLE-MANAGE")
  public VehicleResponse update(
      @PathVariable UUID vehicleId,
      @Valid @RequestBody UpdateVehicleRequest request,
      CurrentActor actor) {

    UpdateVehicleCommand command =
        new UpdateVehicleCommand(
            VehicleId.of(vehicleId),
            request.displayName(),
            SeatingCapacity.of(request.seatingCapacity()),
            request.vendorName(),
            actor.userId(),
            actor.role());

    return VehicleResponse.from(updateVehicle.execute(command));
  }

  /**
   * Lets a fleet manager see why a vehicle is blocked before 06:30, rather than discovering it when
   * a driver cannot start (feature FLT-003, BR-FLEET-002).
   */
  @GetMapping("/{vehicleId}/eligibility")
  @RequiresPermission("PERM-VEHICLE-VIEW")
  public VehicleEligibilityResponse eligibility(@PathVariable UUID vehicleId) {
    return VehicleEligibilityResponse.from(getVehicleEligibility.execute(VehicleId.of(vehicleId)));
  }
}
