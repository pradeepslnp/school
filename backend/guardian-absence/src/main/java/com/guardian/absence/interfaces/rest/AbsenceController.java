package com.guardian.absence.interfaces.rest;

import com.guardian.absence.application.command.DeclareAbsenceCommand;
import com.guardian.absence.application.usecase.CancelAbsenceUseCase;
import com.guardian.absence.application.usecase.DeclareAbsenceUseCase;
import com.guardian.absence.application.usecase.ListAbsencesUseCase;
import com.guardian.absence.domain.Absence;
import com.guardian.absence.interfaces.rest.dto.AbsenceResponse;
import com.guardian.absence.interfaces.rest.dto.DeclareAbsenceRequest;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
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
 * Absence endpoints — features ABS-001 and ABS-003, screen P-06. See
 * guardian-docs/04-api/TRIPS_BOARDING_API.md § Absence.
 *
 * <p>This layer only translates: parse the wire format, call one use case, map back. Every rule —
 * the declare right, the trip-started refusal, cancellation semantics — lives in the use cases,
 * because a rule enforced in a controller is a rule the next caller can bypass.
 */
@RestController
@RequestMapping("/api/v1")
public class AbsenceController {

  private final DeclareAbsenceUseCase declareAbsence;
  private final ListAbsencesUseCase listAbsences;
  private final CancelAbsenceUseCase cancelAbsence;

  public AbsenceController(
      DeclareAbsenceUseCase declareAbsence,
      ListAbsencesUseCase listAbsences,
      CancelAbsenceUseCase cancelAbsence) {
    this.declareAbsence = declareAbsence;
    this.listAbsences = listAbsences;
    this.cancelAbsence = cancelAbsence;
  }

  /**
   * Declares a child absent.
   *
   * <p>Not idempotent and deliberately not given an idempotency key: a duplicate declaration is
   * harmless (the same child excluded from the same manifest twice is the same outcome), so the
   * complexity of deduplication buys nothing here. Contrast boarding events, where a duplicate
   * records a child boarding twice.
   */
  @PostMapping("/students/{studentId}/absences")
  @RequiresPermission("PERM-ABSENCE-DECLARE")
  public ResponseEntity<AbsenceResponse> declare(
      @PathVariable UUID studentId,
      @Valid @RequestBody DeclareAbsenceRequest request,
      CurrentActor actor) {

    Absence declared =
        declareAbsence.execute(
            new DeclareAbsenceCommand(
                studentId,
                request.fromDate(),
                request.toDate(),
                request.direction() == null ? null : Absence.Direction.valueOf(request.direction()),
                request.reason(),
                actor.userId(),
                actor.role()));

    return ResponseEntity.created(URI.create("/api/v1/absences/" + declared.id()))
        .body(AbsenceResponse.from(declared));
  }

  @GetMapping("/students/{studentId}/absences")
  @RequiresPermission("PERM-ABSENCE-VIEW")
  public List<AbsenceResponse> list(@PathVariable UUID studentId, CurrentActor actor) {
    return listAbsences.execute(actor.userId(), studentId).stream()
        .map(AbsenceResponse::from)
        .toList();
  }

  /**
   * Cancels a declaration.
   *
   * <p>{@code DELETE} because that is the client's intent, but nothing is deleted — the row is
   * marked cancelled and stays (BR-ABS-004). {@code 204}, so no body has to describe a resource the
   * caller has just discarded.
   */
  @DeleteMapping("/absences/{absenceId}")
  @RequiresPermission("PERM-ABSENCE-DECLARE")
  public ResponseEntity<Void> cancel(@PathVariable UUID absenceId, CurrentActor actor) {
    cancelAbsence.execute(absenceId, actor.userId(), actor.role());
    return ResponseEntity.noContent().build();
  }
}
