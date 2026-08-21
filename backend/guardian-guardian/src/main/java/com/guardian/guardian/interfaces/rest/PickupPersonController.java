package com.guardian.guardian.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.guardian.application.usecase.ListPickupPersonsUseCase;
import com.guardian.guardian.application.usecase.NominatePickupPersonUseCase;
import com.guardian.guardian.application.usecase.RevokePickupPersonUseCase;
import com.guardian.guardian.domain.PickupPerson;
import com.guardian.guardian.interfaces.rest.dto.PickupPersonDtos.NominateRequest;
import com.guardian.guardian.interfaces.rest.dto.PickupPersonDtos.PickupPersonResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Authorised pickup persons — features GRD-004 and GRD-005, screen P-07. See
 * guardian-docs/04-api/STUDENTS_GUARDIANS_API.md.
 *
 * <p>Nested under the student because a nomination has no meaning apart from the child it concerns
 * — ownership nesting, which is the one case API_STANDARDS.md permits it for.
 *
 * <p>Note the asymmetry in declared permissions: reading uses {@code PERM-STUDENT-VIEW}, writing
 * uses {@code PERM-PICKUP-PERSON-MANAGE}. Seeing who may collect your child and adding to that list
 * are different acts, and the second additionally requires the handover right on the relationship
 * (BR-GRD-006), checked in the use case.
 */
@RestController
@RequestMapping("/api/v1/students/{studentId}/pickup-persons")
public class PickupPersonController {

  private final ListPickupPersonsUseCase listPickupPersons;
  private final NominatePickupPersonUseCase nominatePickupPerson;
  private final RevokePickupPersonUseCase revokePickupPerson;

  public PickupPersonController(
      ListPickupPersonsUseCase listPickupPersons,
      NominatePickupPersonUseCase nominatePickupPerson,
      RevokePickupPersonUseCase revokePickupPerson) {
    this.listPickupPersons = listPickupPersons;
    this.nominatePickupPerson = nominatePickupPerson;
    this.revokePickupPerson = revokePickupPerson;
  }

  @GetMapping
  @RequiresPermission("PERM-STUDENT-VIEW")
  public List<PickupPersonResponse> list(@PathVariable UUID studentId, CurrentActor actor) {
    return listPickupPersons.execute(actor.userId(), studentId).stream()
        .map(PickupPersonResponse::from)
        .toList();
  }

  @PostMapping
  @RequiresPermission("PERM-PICKUP-PERSON-MANAGE")
  public ResponseEntity<PickupPersonResponse> nominate(
      @PathVariable UUID studentId,
      @Valid @RequestBody NominateRequest request,
      CurrentActor actor) {

    PickupPerson saved =
        nominatePickupPerson.execute(
            studentId,
            request.fullName(),
            request.phone(),
            request.relationshipNote(),
            request.validFrom(),
            request.validUntil(),
            actor.userId(),
            actor.role());

    return ResponseEntity.created(
            URI.create("/api/v1/students/" + studentId + "/pickup-persons/" + saved.id()))
        .body(PickupPersonResponse.from(saved));
  }

  /** Revocation is immediate (BR-GRD-007). The row is deactivated, never deleted. */
  @DeleteMapping("/{pickupPersonId}")
  @RequiresPermission("PERM-PICKUP-PERSON-MANAGE")
  public ResponseEntity<Void> revoke(
      @PathVariable UUID studentId, @PathVariable UUID pickupPersonId, CurrentActor actor) {

    revokePickupPerson.execute(studentId, pickupPersonId, actor.userId(), actor.role());
    return ResponseEntity.noContent().build();
  }
}
