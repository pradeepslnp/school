package com.guardian.staff.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.staff.application.command.AddStaffCredentialCommand;
import com.guardian.staff.application.usecase.AddStaffCredentialUseCase;
import com.guardian.staff.application.usecase.ListExpiringStaffCredentialsUseCase;
import com.guardian.staff.domain.StaffCredential;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.interfaces.rest.dto.AddStaffCredentialRequest;
import com.guardian.staff.interfaces.rest.dto.StaffCredentialResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Staff credential endpoints (feature STF-002, STF-003). See
 * guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md.
 */
@RestController
public class StaffCredentialController {

  private final AddStaffCredentialUseCase addCredential;
  private final ListExpiringStaffCredentialsUseCase listExpiring;

  public StaffCredentialController(
      AddStaffCredentialUseCase addCredential, ListExpiringStaffCredentialsUseCase listExpiring) {
    this.addCredential = addCredential;
    this.listExpiring = listExpiring;
  }

  @PostMapping("/api/v1/transport-staff/{staffId}/credentials")
  @RequiresPermission("PERM-STAFF-MANAGE")
  public ResponseEntity<StaffCredentialResponse> add(
      @PathVariable UUID staffId,
      @Valid @RequestBody AddStaffCredentialRequest request,
      CurrentActor actor) {

    AddStaffCredentialCommand command =
        new AddStaffCredentialCommand(
            StaffId.of(staffId),
            request.credentialType(),
            request.credentialNumber(),
            request.credentialClass(),
            request.issuedOn(),
            request.expiresOn(),
            request.isMandatory(),
            request.fileRef(),
            actor.userId(),
            actor.role());

    StaffCredential created = addCredential.execute(command);

    return ResponseEntity.created(
            URI.create("/api/v1/transport-staff/" + staffId + "/credentials/" + created.id()))
        .body(StaffCredentialResponse.from(created));
  }

  /** Feeds the manual "who's expiring" view ahead of the daily warning job (BR-STAFF-003). */
  @GetMapping("/api/v1/transport-staff/credentials/expiring")
  @RequiresPermission("PERM-STAFF-MANAGE")
  public List<StaffCredentialResponse> expiring(
      @RequestParam(name = "withinDays", required = false, defaultValue = "30") int withinDays) {
    return listExpiring.withinDays(withinDays).stream().map(StaffCredentialResponse::from).toList();
  }
}
