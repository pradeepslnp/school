package com.guardian.absence.application.usecase;

import com.guardian.absence.application.command.DeclareAbsenceCommand;
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
 * Declares a child absent — feature ABS-001, screen P-06.
 *
 * <p>Three rules, in this order, and the order is the point:
 *
 * <ol>
 *   <li><strong>The caller must hold the right on the relationship</strong> (BR-ABS-001). Holding
 *       {@code PERM-ABSENCE-DECLARE} says a guardian may declare absences; it does not say for
 *       <em>which child</em>. Scope is checked here because no endpoint annotation can express it.
 *   <li><strong>The trip must not have started</strong> (BR-ABS-003). After start the manifest is
 *       already materialised and immutable; changing it then is a manifest amendment, performed by
 *       staff with a reason, not a parent tapping a form.
 *   <li>Only then is the record written, and audited in the same transaction (BR-AUD-002).
 * </ol>
 */
@Service
public class DeclareAbsenceUseCase {

  private final AbsenceRepository absences;
  private final AuditPort audit;

  public DeclareAbsenceUseCase(AbsenceRepository absences, AuditPort audit) {
    this.absences = absences;
    this.audit = audit;
  }

  @Transactional
  @BusinessRule({"BR-ABS-001", "BR-ABS-003"})
  public Absence execute(DeclareAbsenceCommand command) {
    UUID guardianId =
        absences
            .declaringGuardianIdFor(command.actorUserId(), command.studentId())
            // Same refusal for "not your child" and "you lack the right": distinguishing them
            // tells a caller which children exist (BR-IAM-005).
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.AUTH_SCOPE_DENIED, "student", command.studentId()));

    rejectIfTripStarted(command);

    Absence declared =
        new Absence(
            null,
            command.studentId(),
            guardianId,
            command.fromDate(),
            command.toDate(),
            command.direction(),
            blankToNull(command.reason()),
            Absence.Status.ACTIVE);

    Absence saved = absences.save(declared, command.actorUserId());

    // In the same transaction as the write (BR-AUD-002 🔴): if the audit fails, the declaration
    // rolls back with it. An absence that silently excluded a child from a manifest with no
    // record of who declared it is exactly the gap reconciliation cannot explain afterwards.
    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(command.actorUserId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("ABSENCE_DECLARED")
            .subject("Absence", saved.id())
            .after(
                Map.of(
                    "studentId", command.studentId().toString(),
                    "fromDate", command.fromDate().toString(),
                    "toDate", command.toDate().toString(),
                    "direction", command.direction() == null ? "BOTH" : command.direction().name()))
            .build());

    return saved;
  }

  /**
   * Refuses a declaration for a run that is already under way.
   *
   * <p>Checked per day across the range rather than once: a Monday-to-Friday declaration made on
   * Monday morning, after the morning bus has left, is legitimate for Tuesday onwards but not for
   * the run already in progress. Refusing the whole range would make the parent re-enter it;
   * accepting it silently would claim to have excluded a child from a manifest that is already
   * fixed.
   */
  private void rejectIfTripStarted(DeclareAbsenceCommand command) {
    for (LocalDate date = command.fromDate();
        !date.isAfter(command.toDate());
        date = date.plusDays(1)) {

      for (Absence.Direction run : runsCovered(command.direction())) {
        if (absences.tripAlreadyStarted(command.studentId(), date, run)) {
          throw new BusinessRuleViolationException(
              ErrorCode.ABSENCE_TRIP_ALREADY_STARTED,
              "BR-ABS-003",
              Map.of("serviceDate", date.toString(), "direction", run.name()));
        }
      }
    }
  }

  private static Absence.Direction[] runsCovered(Absence.Direction direction) {
    return direction == null ? Absence.Direction.values() : new Absence.Direction[] {direction};
  }

  private static String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }
}
