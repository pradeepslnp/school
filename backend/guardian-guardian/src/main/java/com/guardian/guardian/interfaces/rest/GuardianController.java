package com.guardian.guardian.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.guardian.application.usecase.UpdateGuardianUseCase;
import com.guardian.guardian.interfaces.rest.dto.GuardianDtos.GuardianDetailsResponse;
import com.guardian.guardian.interfaces.rest.dto.GuardianDtos.UpdateGuardianRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The guardian record itself, apart from any one child (feature GRD-001). See
 * guardian-docs/04-api/STUDENTS_GUARDIANS_API.md § Guardians.
 *
 * <p>A guardian's links to children, and the rights on each, are {@link GuardianLinkController}'s.
 * This layer only translates: parse the wire format, call one use case, map the result back.
 */
@RestController
@RequestMapping("/api/v1/guardians")
public class GuardianController {

  private final UpdateGuardianUseCase updateGuardian;

  public GuardianController(UpdateGuardianUseCase updateGuardian) {
    this.updateGuardian = updateGuardian;
  }

  /** BR-IAM-014: a corrected phone moves the guardian's sign-in to the new number. */
  @PatchMapping("/{guardianId}")
  @RequiresPermission("PERM-GUARDIAN-MANAGE")
  public GuardianDetailsResponse update(
      @PathVariable UUID guardianId,
      @Valid @RequestBody UpdateGuardianRequest request,
      CurrentActor actor) {

    return GuardianDetailsResponse.from(
        updateGuardian.execute(
            guardianId,
            request.firstName(),
            request.lastName(),
            request.phone(),
            request.email(),
            actor.userId(),
            actor.role()));
  }
}
