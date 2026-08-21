package com.guardian.student.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.student.application.command.UpdateStudentCommand;
import com.guardian.student.application.port.StudentRepository;
import com.guardian.student.domain.Student;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Corrects a student's details (feature STU-001). */
@Service
@BusinessRule({"BR-STU-001", "BR-AUD-002"})
public class UpdateStudentUseCase {

  private final StudentRepository studentRepository;
  private final AuditPort auditPort;

  public UpdateStudentUseCase(StudentRepository studentRepository, AuditPort auditPort) {
    this.studentRepository = studentRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public Student execute(UpdateStudentCommand command) {
    TenantId tenantId = TenantContext.require();

    Student existing =
        studentRepository
            .findById(command.studentId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STUDENT_NOT_FOUND, "Student", command.studentId().value()));

    Student updated =
        existing.updateDetails(
            command.firstName(),
            command.lastName(),
            command.dateOfBirth(),
            command.branchId(),
            command.studentClassId(),
            command.transportEligible());

    Student saved = studentRepository.save(updated);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("STUDENT_UPDATED")
            .subject("Student", saved.id().value())
            .before(describe(existing))
            .after(describe(saved))
            .build());

    return saved;
  }

  /**
   * Transport eligibility and placement, not names.
   *
   * <p>What matters after an incident is whether the child was supposed to be on a bus and which
   * class they belonged to — not the spelling correction someone made to a surname.
   */
  private static Map<String, Object> describe(Student student) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("transportEligible", String.valueOf(student.transportEligible()));
    values.put("branchId", student.branchId().map(Object::toString).orElse(null));
    values.put("studentClassId", student.studentClassId().map(Object::toString).orElse(null));
    return values;
  }
}
