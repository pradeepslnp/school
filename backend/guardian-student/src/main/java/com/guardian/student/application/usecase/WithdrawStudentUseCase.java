package com.guardian.student.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.student.application.port.StudentRepository;
import com.guardian.student.domain.EnrolmentStatus;
import com.guardian.student.domain.Student;
import com.guardian.student.domain.StudentId;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Takes a student off the roll (feature STU-004).
 *
 * <p>BR-STU-005: <strong>soft withdrawal only — no delete path exists anywhere in this
 * module.</strong> Boarding events, handovers, and incidents reference a student and are the
 * evidence of what happened to a child. Deleting the subject would leave those records pointing at
 * nothing, which is precisely the state an investigation cannot recover from.
 *
 * <p>Route assignments for the withdrawn student are MOD-07's to clear. That module does not read
 * this one's tables (MODULE_MAP cross-module rule 1), so the removal happens when route assignment
 * exists — until then a withdrawn student is refused at assignment time by BR-STU-004 instead.
 */
@Service
@BusinessRule({"BR-STU-005", "BR-AUD-002"})
public class WithdrawStudentUseCase {

  private final StudentRepository studentRepository;
  private final AuditPort auditPort;

  public WithdrawStudentUseCase(StudentRepository studentRepository, AuditPort auditPort) {
    this.studentRepository = studentRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public Student execute(StudentId studentId, UUID actorId, String actorRole, String reason) {
    TenantId tenantId = TenantContext.require();

    Student student =
        studentRepository
            .findById(studentId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STUDENT_NOT_FOUND, "Student", studentId.value()));

    // Idempotent: withdrawing an already-withdrawn student is a no-op rather than an error, and
    // writes no audit record — a second identical entry would suggest a second decision.
    if (student.enrolmentStatus() == EnrolmentStatus.WITHDRAWN) {
      return student;
    }

    Student withdrawn = studentRepository.save(student.withdraw());

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("STUDENT_WITHDRAWN")
            .subject("Student", withdrawn.id().value())
            .reason(reason)
            .before(Map.of("enrolmentStatus", student.enrolmentStatus().name()))
            .after(Map.of("enrolmentStatus", withdrawn.enrolmentStatus().name()))
            .build());

    return withdrawn;
  }
}
