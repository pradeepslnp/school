package com.guardian.student.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.student.application.command.CreateStudentCommand;
import com.guardian.student.application.port.StudentRepository;
import com.guardian.student.domain.Student;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Enrols a student (feature STU-001). */
@Service
@BusinessRule({"BR-STU-001", "BR-STU-003", "BR-AUD-002"})
public class CreateStudentUseCase {

  private final StudentRepository studentRepository;
  private final AuditPort auditPort;

  public CreateStudentUseCase(StudentRepository studentRepository, AuditPort auditPort) {
    this.studentRepository = studentRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public Student execute(CreateStudentCommand command) {
    TenantId tenantId = TenantContext.require();

    // BR-STU-003: admission numbers are unique within a school. Checked here rather than left to
    // uq_students_admission because the constraint violation would surface as a 500 with no
    // indication of which field the office needs to correct — and on a bulk import, which row.
    if (studentRepository.existsByAdmissionNo(command.schoolId(), command.admissionNo())) {
      throw new BusinessRuleViolationException(
          ErrorCode.STUDENT_ADMISSION_NO_EXISTS,
          "BR-STU-003",
          Map.of("admissionNo", command.admissionNo().value()));
    }

    Student student =
        Student.create(
            tenantId,
            command.schoolId(),
            command.branchId(),
            command.studentClassId(),
            command.admissionNo(),
            command.firstName(),
            command.lastName(),
            command.dateOfBirth(),
            command.transportEligible());

    Student saved = studentRepository.save(student);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("STUDENT_CREATED")
            .subject("Student", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  /**
   * Identifiers and status only.
   *
   * <p>The child's name is deliberately absent: audit records are retained far longer than the
   * enrolment and are read by people investigating an incident, not by the office. The admission
   * number identifies the student to anyone entitled to resolve it (DEFINITION_OF_DONE.md §6).
   */
  private static Map<String, Object> describe(Student student) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("admissionNo", student.admissionNo().value());
    values.put("schoolId", student.schoolId().toString());
    values.put("enrolmentStatus", student.enrolmentStatus().name());
    values.put("transportEligible", String.valueOf(student.transportEligible()));
    return values;
  }
}
