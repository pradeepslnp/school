package com.guardian.staff.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.staff.application.command.CreateTransportStaffCommand;
import com.guardian.staff.application.command.UpdateTransportStaffCommand;
import com.guardian.staff.application.command.VerifyStaffCommand;
import com.guardian.staff.application.usecase.CreateTransportStaffUseCase;
import com.guardian.staff.application.usecase.DeactivateStaffUseCase;
import com.guardian.staff.application.usecase.GetStaffEligibilityUseCase;
import com.guardian.staff.application.usecase.GetTransportStaffUseCase;
import com.guardian.staff.application.usecase.UpdateTransportStaffUseCase;
import com.guardian.staff.application.usecase.VerifyStaffUseCase;
import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.TransportStaff;
import com.guardian.staff.interfaces.rest.dto.CreateTransportStaffRequest;
import com.guardian.staff.interfaces.rest.dto.DeactivateStaffRequest;
import com.guardian.staff.interfaces.rest.dto.StaffEligibilityResponse;
import com.guardian.staff.interfaces.rest.dto.TransportStaffResponse;
import com.guardian.staff.interfaces.rest.dto.UpdateTransportStaffRequest;
import com.guardian.staff.interfaces.rest.dto.VerifyStaffRequest;
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
 * Transport staff endpoints (feature STF-001, STF-003, IAM-008). See
 * guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md.
 *
 * <p>Every method declares a permission from the permission matrix — an architecture test fails the
 * build for any endpoint that does not (BR-IAM-002). This layer only translates: parse the wire
 * format into domain types, call one use case, map the result back.
 *
 * <p>Unlike vehicles, the API spec gives staff a single {@code PERM-STAFF-MANAGE} for both reading
 * and writing — there is no separate {@code PERM-STAFF-VIEW}.
 */
@RestController
@RequestMapping("/api/v1/transport-staff")
public class TransportStaffController {

  private final CreateTransportStaffUseCase createStaff;
  private final GetTransportStaffUseCase getStaff;
  private final UpdateTransportStaffUseCase updateStaff;
  private final VerifyStaffUseCase verifyStaff;
  private final DeactivateStaffUseCase deactivateStaff;
  private final GetStaffEligibilityUseCase getStaffEligibility;

  public TransportStaffController(
      CreateTransportStaffUseCase createStaff,
      GetTransportStaffUseCase getStaff,
      UpdateTransportStaffUseCase updateStaff,
      VerifyStaffUseCase verifyStaff,
      DeactivateStaffUseCase deactivateStaff,
      GetStaffEligibilityUseCase getStaffEligibility) {
    this.createStaff = createStaff;
    this.getStaff = getStaff;
    this.updateStaff = updateStaff;
    this.verifyStaff = verifyStaff;
    this.deactivateStaff = deactivateStaff;
    this.getStaffEligibility = getStaffEligibility;
  }

  @PostMapping
  @RequiresPermission("PERM-STAFF-MANAGE")
  public ResponseEntity<TransportStaffResponse> create(
      @Valid @RequestBody CreateTransportStaffRequest request, CurrentActor actor) {

    CreateTransportStaffCommand command =
        new CreateTransportStaffCommand(
            SchoolId.of(request.schoolId()),
            StaffType.valueOf(request.staffType()),
            request.employeeCode(),
            request.firstName(),
            request.lastName(),
            request.phone(),
            request.vendorName(),
            actor.userId(),
            actor.role());

    TransportStaff created = createStaff.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/transport-staff/" + created.id()))
        .body(TransportStaffResponse.from(created));
  }

  /**
   * Not in FLEET_STAFF_ROUTES_API.md's endpoint table, which documents only the list form — this
   * completes the resource the same way {@code GET /vehicles/{vehicleId}} completes vehicles.
   */
  @GetMapping("/{staffId}")
  @RequiresPermission("PERM-STAFF-MANAGE")
  public TransportStaffResponse getById(@PathVariable UUID staffId) {
    return TransportStaffResponse.from(getStaff.byId(StaffId.of(staffId)));
  }

  /** BR-IAM-006: results are scoped to what the caller's role and assignment permit. */
  @GetMapping
  @RequiresPermission("PERM-STAFF-MANAGE")
  public List<TransportStaffResponse> listBySchool(@RequestParam UUID schoolId) {
    return getStaff.bySchool(SchoolId.of(schoolId)).stream()
        .map(TransportStaffResponse::from)
        .toList();
  }

  @PatchMapping("/{staffId}")
  @RequiresPermission("PERM-STAFF-MANAGE")
  public TransportStaffResponse update(
      @PathVariable UUID staffId,
      @Valid @RequestBody UpdateTransportStaffRequest request,
      CurrentActor actor) {

    UpdateTransportStaffCommand command =
        new UpdateTransportStaffCommand(
            StaffId.of(staffId),
            request.firstName(),
            request.lastName(),
            request.phone(),
            request.employeeCode(),
            request.vendorName(),
            actor.userId(),
            actor.role());

    return TransportStaffResponse.from(updateStaff.execute(command));
  }

  @PostMapping("/{staffId}/verify")
  @RequiresPermission("PERM-STAFF-VERIFY")
  public TransportStaffResponse verify(
      @PathVariable UUID staffId,
      @Valid @RequestBody VerifyStaffRequest request,
      CurrentActor actor) {

    VerifyStaffCommand command =
        new VerifyStaffCommand(
            StaffId.of(staffId),
            request.verificationType(),
            request.verifiedUntil(),
            request.referenceNumber(),
            actor.userId(),
            actor.role());

    return TransportStaffResponse.from(verifyStaff.execute(command));
  }

  /**
   * BR-IAM-008: deactivation revokes sessions and future duty assignments — enforced by
   * MOD-02/MOD-07, not here.
   */
  @PostMapping("/{staffId}/deactivate")
  @RequiresPermission("PERM-STAFF-MANAGE")
  public TransportStaffResponse deactivate(
      @PathVariable UUID staffId,
      @RequestBody(required = false) DeactivateStaffRequest request,
      CurrentActor actor) {

    String reason = request == null ? null : request.reason();
    return TransportStaffResponse.from(
        deactivateStaff.execute(StaffId.of(staffId), actor.userId(), actor.role(), reason));
  }

  /**
   * Lets a transport manager see why a driver or attendant is blocked before 06:30, rather than
   * discovering it when a trip cannot start (feature STF-003, BR-STAFF-001/002).
   */
  @GetMapping("/{staffId}/eligibility")
  @RequiresPermission("PERM-STAFF-MANAGE")
  public StaffEligibilityResponse eligibility(@PathVariable UUID staffId) {
    return StaffEligibilityResponse.from(getStaffEligibility.execute(StaffId.of(staffId)));
  }
}
