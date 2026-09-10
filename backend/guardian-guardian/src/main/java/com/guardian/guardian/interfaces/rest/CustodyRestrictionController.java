package com.guardian.guardian.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.guardian.application.usecase.LiftCustodyRestrictionUseCase;
import com.guardian.guardian.application.usecase.ListCustodyRestrictionsUseCase;
import com.guardian.guardian.application.usecase.RecordCustodyRestrictionUseCase;
import com.guardian.guardian.domain.CustodyRestriction;
import com.guardian.guardian.interfaces.rest.dto.CustodyRestrictionDtos.CustodyRestrictionResponse;
import com.guardian.guardian.interfaces.rest.dto.CustodyRestrictionDtos.RecordRequest;
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
 * Custody restrictions — feature GRD-006, screen A-14. See
 * guardian-docs/04-api/STUDENTS_GUARDIANS_API.md § Custody Restrictions.
 *
 * <p>Nested under the student (ownership nesting, the case API_STANDARDS.md permits).
 *
 * <p>Every method requires {@code PERM-CUSTODY-RESTRICTION-MANAGE} — read included. Unlike pickup
 * persons, there is no wider read audience: a restriction is invisible to the restricted person and
 * to every guardian, and the console is the only surface that shows one (BR-GRD-008 🔴).
 */
@RestController
@RequestMapping("/api/v1/students/{studentId}/custody-restrictions")
public class CustodyRestrictionController {

  private final ListCustodyRestrictionsUseCase listRestrictions;
  private final RecordCustodyRestrictionUseCase recordRestriction;
  private final LiftCustodyRestrictionUseCase liftRestriction;

  public CustodyRestrictionController(
      ListCustodyRestrictionsUseCase listRestrictions,
      RecordCustodyRestrictionUseCase recordRestriction,
      LiftCustodyRestrictionUseCase liftRestriction) {
    this.listRestrictions = listRestrictions;
    this.recordRestriction = recordRestriction;
    this.liftRestriction = liftRestriction;
  }

  @GetMapping
  @RequiresPermission("PERM-CUSTODY-RESTRICTION-MANAGE")
  public List<CustodyRestrictionResponse> list(@PathVariable UUID studentId, CurrentActor actor) {
    return listRestrictions.execute(studentId).stream()
        .map(CustodyRestrictionResponse::from)
        .toList();
  }

  @PostMapping
  @RequiresPermission("PERM-CUSTODY-RESTRICTION-MANAGE")
  public ResponseEntity<CustodyRestrictionResponse> record(
      @PathVariable UUID studentId, @Valid @RequestBody RecordRequest request, CurrentActor actor) {

    CustodyRestriction saved =
        recordRestriction.execute(
            studentId,
            request.restrictedGuardianId(),
            request.restrictedPersonName(),
            request.restrictionType(),
            request.reason(),
            request.effectiveFrom(),
            request.effectiveUntil(),
            actor.userId(),
            actor.role());

    return ResponseEntity.created(
            URI.create("/api/v1/students/" + studentId + "/custody-restrictions/" + saved.id()))
        .body(CustodyRestrictionResponse.from(saved));
  }

  /** Lifting is immediate; the row is deactivated, never deleted. */
  @DeleteMapping("/{restrictionId}")
  @RequiresPermission("PERM-CUSTODY-RESTRICTION-MANAGE")
  public ResponseEntity<Void> lift(
      @PathVariable UUID studentId, @PathVariable UUID restrictionId, CurrentActor actor) {

    liftRestriction.execute(studentId, restrictionId, actor.userId(), actor.role());
    return ResponseEntity.noContent().build();
  }
}
