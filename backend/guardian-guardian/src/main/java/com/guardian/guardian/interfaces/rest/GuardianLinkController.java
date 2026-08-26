package com.guardian.guardian.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.guardian.application.port.GuardianRepository.StudentGuardian;
import com.guardian.guardian.application.usecase.AddGuardianToStudentUseCase;
import com.guardian.guardian.application.usecase.ListGuardiansForStudentUseCase;
import com.guardian.guardian.interfaces.rest.dto.GuardianLinkDtos.AddGuardianRequest;
import com.guardian.guardian.interfaces.rest.dto.GuardianLinkDtos.GuardianResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * A student's guardians — features GRD-001 and GRD-002, screen A-11. See
 * guardian-docs/04-api/STUDENTS_GUARDIANS_API.md § Guardian–Student Links.
 *
 * <p>Nested under the student because a link has no meaning apart from the child it concerns —
 * ownership nesting, the one case API_STANDARDS.md permits it for, matching {@code
 * PickupPersonController}.
 *
 * <p>The declared permissions are asymmetric on purpose: reading a child's guardians uses {@code
 * PERM-STUDENT-VIEW}, adding one uses {@code PERM-GUARDIAN-LINK}. Seeing who is on the list and
 * changing who is on it are different acts.
 */
@RestController
@RequestMapping("/api/v1/students/{studentId}/guardians")
public class GuardianLinkController {

  private final ListGuardiansForStudentUseCase listGuardians;
  private final AddGuardianToStudentUseCase addGuardian;

  public GuardianLinkController(
      ListGuardiansForStudentUseCase listGuardians, AddGuardianToStudentUseCase addGuardian) {
    this.listGuardians = listGuardians;
    this.addGuardian = addGuardian;
  }

  @GetMapping
  @RequiresPermission("PERM-STUDENT-VIEW")
  public List<GuardianResponse> list(@PathVariable UUID studentId) {
    return listGuardians.execute(studentId).stream().map(GuardianResponse::from).toList();
  }

  @PostMapping
  @RequiresPermission("PERM-GUARDIAN-LINK")
  public ResponseEntity<GuardianResponse> add(
      @PathVariable UUID studentId,
      @Valid @RequestBody AddGuardianRequest request,
      CurrentActor actor) {

    StudentGuardian saved =
        addGuardian.execute(
            studentId,
            request.firstName(),
            request.lastName(),
            request.phone(),
            request.email(),
            request.relationshipType(),
            request.canViewOrDefault(),
            request.canReceiveNotificationsOrDefault(),
            request.canAuthoriseHandoverOrDefault(),
            request.canDeclareAbsenceOrDefault(),
            request.isPrimaryOrDefault(),
            actor.userId(),
            actor.role());

    return ResponseEntity.created(
            URI.create("/api/v1/students/" + studentId + "/guardians/" + saved.linkId()))
        .body(GuardianResponse.from(saved));
  }
}
