package com.guardian.tenancy.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.tenancy.application.command.CreateOrganizationCommand;
import com.guardian.tenancy.application.command.UpdateOrganizationCommand;
import com.guardian.tenancy.application.usecase.CreateOrganizationUseCase;
import com.guardian.tenancy.application.usecase.GetOrganizationUseCase;
import com.guardian.tenancy.application.usecase.ListOrganizationsUseCase;
import com.guardian.tenancy.application.usecase.UpdateOrganizationUseCase;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationCode;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.interfaces.rest.dto.CreateOrganizationRequest;
import com.guardian.tenancy.interfaces.rest.dto.OrganizationResponse;
import com.guardian.tenancy.interfaces.rest.dto.UpdateOrganizationRequest;
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
import org.springframework.web.bind.annotation.RestController;

/**
 * Organization endpoints (feature TEN-001). See guardian-docs/04-api/TENANCY_IDENTITY_API.md.
 *
 * <p>Every method declares a permission from the permission matrix — {@code PERM-ORG-CREATE} and
 * {@code PERM-ORG-VIEW} are held only by {@code SUPER_ADMIN} and {@code ORG_ADMIN}
 * (PERMISSION_MATRIX.md), which is what actually distinguishes "onboard a new organization" from
 * every other role in this system, rather than anything decided in this class.
 *
 * <p>This layer only translates: parse the wire format into domain types, call one use case, map
 * the result back. No business logic, no repository access — matching {@code SchoolController}.
 */
@RestController
@RequestMapping("/api/v1/organizations")
public class OrganizationController {

  private final CreateOrganizationUseCase createOrganization;
  private final GetOrganizationUseCase getOrganization;
  private final ListOrganizationsUseCase listOrganizations;
  private final UpdateOrganizationUseCase updateOrganization;

  public OrganizationController(
      CreateOrganizationUseCase createOrganization,
      GetOrganizationUseCase getOrganization,
      ListOrganizationsUseCase listOrganizations,
      UpdateOrganizationUseCase updateOrganization) {
    this.createOrganization = createOrganization;
    this.getOrganization = getOrganization;
    this.listOrganizations = listOrganizations;
    this.updateOrganization = updateOrganization;
  }

  /**
   * {@code SUPER_ADMIN} only, enforced in {@link ListOrganizationsUseCase} itself rather than by
   * {@code @RequiresPermission} alone — see that class's documentation for why {@code
   * PERM-ORG-VIEW} cannot be the whole answer here.
   */
  @GetMapping
  @RequiresPermission("PERM-ORG-VIEW")
  public List<OrganizationResponse> list(CurrentActor actor) {
    return listOrganizations.execute(actor.role()).stream()
        .map(OrganizationResponse::from)
        .toList();
  }

  @PostMapping
  @RequiresPermission("PERM-ORG-CREATE")
  public ResponseEntity<OrganizationResponse> create(
      @Valid @RequestBody CreateOrganizationRequest request, CurrentActor actor) {

    CreateOrganizationCommand command =
        new CreateOrganizationCommand(
            OrganizationCode.of(request.code()),
            request.name(),
            request.regionProfileCode(),
            request.contactEmail(),
            request.contactPhone(),
            actor.userId(),
            actor.role());

    Organization created = createOrganization.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/organizations/" + created.id()))
        .body(OrganizationResponse.from(created));
  }

  @GetMapping("/{organizationId}")
  @RequiresPermission("PERM-ORG-VIEW")
  public OrganizationResponse getById(@PathVariable UUID organizationId) {
    return OrganizationResponse.from(getOrganization.byId(OrganizationId.of(organizationId)));
  }

  @PatchMapping("/{organizationId}")
  @RequiresPermission("PERM-ORG-EDIT")
  public OrganizationResponse update(
      @PathVariable UUID organizationId,
      @Valid @RequestBody UpdateOrganizationRequest request,
      CurrentActor actor) {

    UpdateOrganizationCommand command =
        new UpdateOrganizationCommand(
            OrganizationId.of(organizationId),
            request.name(),
            request.regionProfileCode(),
            request.contactEmail(),
            request.contactPhone(),
            actor.userId(),
            actor.role());

    return OrganizationResponse.from(updateOrganization.execute(command));
  }
}
