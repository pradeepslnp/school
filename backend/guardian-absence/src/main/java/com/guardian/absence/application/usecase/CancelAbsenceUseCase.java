package com.guardian.absence.application.usecase;

import com.guardian.absence.application.port.AbsenceRepository;
import com.guardian.absence.domain.Absence;
import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Cancels a declared absence — feature ABS-003.
 *
 * <p>"Cancel" is a status change, never a delete (BR-ABS-004). A manifest may already have been
 * materialised from this declaration, and the reason a child was excluded from a trip has to stay
 * answerable afterwards. The endpoint is a {@code DELETE} because that is the client's intent; the
 * database keeps the row.
 *
 * <p>Refused once the trip has started, for the same reason declaring one is: the manifest is fixed
 * by then, and re-adding a child to a running trip is a staff amendment with a reason.
 */
@Service
public class CancelAbsenceUseCase {

  private final AbsenceRepository absences;
  private final AuditPort audit;

  public CancelAbsenceUseCase(AbsenceRepository absences, AuditPort audit) {
    this.absences = absences;
    this.audit = audit;
  }

  @Transactional
  @BusinessRule("BR-ABS-004")
  public void execute(UUID absenceId, UUID actorUserId, String actorRole) {
    Absence absence =
        absences
            .findById(absenceId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.AUTH_SCOPE_DENIED, "absence", absenceId));

    // Scope: the caller must be a guardian of the child this absence belongs to. Without this,
    // knowing an absence id would be enough to cancel a stranger's declaration and put their
    // child back on a manifest.
    if (absences.declaringGuardianIdFor(actorUserId, absence.studentId()).isEmpty()) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "absence", absenceId);
    }

    LocalDate today = LocalDate.now();
    for (Absence.Direction run : Absence.Direction.values()) {
      if (absence.covers(today, run)
          && absences.tripAlreadyStarted(absence.studentId(), today, run)) {
        throw new BusinessRuleViolationException(
            ErrorCode.ABSENCE_TRIP_ALREADY_STARTED,
            "BR-ABS-004",
            Map.of("absenceId", absenceId.toString(), "direction", run.name()));
      }
    }

    absences.cancel(absenceId, actorUserId);

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("ABSENCE_CANCELLED")
            .subject("Absence", absenceId)
            .before(Map.of("status", Absence.Status.ACTIVE.name()))
            .after(Map.of("status", Absence.Status.CANCELLED.name()))
            .build());
  }
}
