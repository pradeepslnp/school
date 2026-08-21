package com.guardian.tenancy.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.tenancy.application.command.CreateSchoolCommand;
import com.guardian.tenancy.application.command.UpdateSchoolCommand;
import com.guardian.tenancy.application.usecase.CreateSchoolUseCase;
import com.guardian.tenancy.application.usecase.DeactivateSchoolUseCase;
import com.guardian.tenancy.application.usecase.GetSchoolUseCase;
import com.guardian.tenancy.application.usecase.UpdateSchoolUseCase;
import com.guardian.tenancy.domain.Coordinates;
import com.guardian.tenancy.domain.GeofenceRadius;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolCode;
import com.guardian.tenancy.domain.SchoolId;
import com.guardian.tenancy.interfaces.rest.dto.CreateSchoolRequest;
import com.guardian.tenancy.interfaces.rest.dto.SchoolResponse;
import com.guardian.tenancy.interfaces.rest.dto.UpdateSchoolRequest;
import jakarta.validation.Valid;
import java.net.URI;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * School endpoints (feature TEN-002). See guardian-docs/04-api/TENANCY_IDENTITY_API.md.
 *
 * <p>Every method declares a permission from the permission matrix. An architecture test fails the
 * build for any endpoint that does not (BR-IAM-002) — deny-by-default is enforced at compile time,
 * not left to review.
 *
 * <p>This layer only translates: parse the wire format into domain types, call one use case, map
 * the result back. No business logic, no repository access.
 */
@RestController
@RequestMapping("/api/v1/schools")
public class SchoolController {

  private final CreateSchoolUseCase createSchool;
  private final GetSchoolUseCase getSchool;
  private final DeactivateSchoolUseCase deactivateSchool;
  private final UpdateSchoolUseCase updateSchool;

  public SchoolController(
      CreateSchoolUseCase createSchool,
      GetSchoolUseCase getSchool,
      DeactivateSchoolUseCase deactivateSchool,
      UpdateSchoolUseCase updateSchool) {
    this.createSchool = createSchool;
    this.getSchool = getSchool;
    this.deactivateSchool = deactivateSchool;
    this.updateSchool = updateSchool;
  }

  @PostMapping
  @RequiresPermission("PERM-SCHOOL-CREATE")
  public ResponseEntity<SchoolResponse> create(
      @Valid @RequestBody CreateSchoolRequest request, CurrentActor actor) {

    CreateSchoolCommand command =
        new CreateSchoolCommand(
            OrganizationId.of(request.organizationId()),
            SchoolCode.of(request.code()),
            request.name(),
            ZoneId.of(request.timezone()),
            new Coordinates(request.latitude(), request.longitude()),
            GeofenceRadius.ofMetres(request.geofenceRadiusM()),
            actor.userId(),
            actor.role());

    School created = createSchool.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/schools/" + created.id()))
        .body(SchoolResponse.from(created));
  }

  @GetMapping("/{schoolId}")
  @RequiresPermission("PERM-SCHOOL-VIEW")
  public SchoolResponse getById(@PathVariable UUID schoolId) {
    return SchoolResponse.from(getSchool.byId(SchoolId.of(schoolId)));
  }

  @GetMapping
  @RequiresPermission("PERM-SCHOOL-VIEW")
  public List<SchoolResponse> listActive(@RequestParam UUID organizationId) {
    return getSchool.activeByOrganization(OrganizationId.of(organizationId)).stream()
        .map(SchoolResponse::from)
        .toList();
  }

  @PatchMapping("/{schoolId}")
  @RequiresPermission("PERM-SCHOOL-EDIT")
  public SchoolResponse update(
      @PathVariable UUID schoolId,
      @Valid @RequestBody UpdateSchoolRequest request,
      CurrentActor actor) {

    UpdateSchoolCommand command =
        new UpdateSchoolCommand(
            SchoolId.of(schoolId),
            OrganizationId.of(request.organizationId()),
            request.name(),
            ZoneId.of(request.timezone()),
            new Coordinates(request.latitude(), request.longitude()),
            GeofenceRadius.ofMetres(request.geofenceRadiusM()),
            actor.userId(),
            actor.role());

    return SchoolResponse.from(updateSchool.execute(command));
  }

  /** Soft deactivation — no hard delete exists, because safety records reference schools. */
  @DeleteMapping("/{schoolId}")
  @RequiresPermission("PERM-SCHOOL-EDIT")
  public SchoolResponse deactivate(
      @PathVariable UUID schoolId,
      @RequestParam(required = false) String reason,
      CurrentActor actor) {
    return SchoolResponse.from(
        deactivateSchool.execute(SchoolId.of(schoolId), actor.userId(), actor.role(), reason));
  }
}
