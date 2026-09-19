package com.guardian.student.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.security.AccessScope;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.student.application.port.StudentRepository;
import com.guardian.student.application.port.StudentSetupRowsPort;
import com.guardian.student.domain.Student;
import com.guardian.student.domain.StudentId;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Permanently removes a student record entered by mistake — a duplicate, or one under the wrong
 * admission number, which cannot be edited because safety records cite it (feature STU-008,
 * BR-STU-007, ADR-0019). A child who was actually on the roll is withdrawn instead ({@link
 * WithdrawStudentUseCase}, BR-STU-005).
 *
 * <p><strong>The database decides whether the student has history.</strong> The student's own setup
 * rows — guardian links, route assignments, boarding credentials — are removed first. Every other
 * table referencing {@code students} (boarding, manifests, absences, notifications, handover codes,
 * custody restrictions, pickup nominations) is {@code ON DELETE RESTRICT}, so if any such row
 * exists the final delete is refused and answered {@code 422 STUDENT_HAS_SAFETY_RECORDS}. Nothing
 * here lists those tables: a table added later is protected by its own foreign key.
 *
 * <p>Everything happens in one transaction, so a refusal rolls back the setup deletions before it
 * and a refused discard changes nothing. Guardian records are kept; they may belong to a sibling.
 *
 * <p>The audit record keeps the admission number, school, and counts — never the child's name
 * (BR-AUD-006).
 */
@Service
@BusinessRule({"BR-STU-007", "BR-AUD-002"})
public class DiscardStudentUseCase {

  private static final int REASON_MAX_LENGTH = 500;

  private final StudentRepository studentRepository;
  private final StudentSetupRowsPort setupRows;
  private final AuditPort auditPort;

  public DiscardStudentUseCase(
      StudentRepository studentRepository, StudentSetupRowsPort setupRows, AuditPort auditPort) {
    this.studentRepository = studentRepository;
    this.setupRows = setupRows;
    this.auditPort = auditPort;
  }

  @Transactional
  public void execute(
      StudentId studentId, String reason, AccessScope scope, UUID actorId, String actorRole) {
    TenantId tenantId = TenantContext.require();
    String trimmedReason = requireReason(reason);

    Student student =
        studentRepository
            .findById(studentId)
            .filter(found -> inScope(scope, found))
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STUDENT_NOT_FOUND, "Student", studentId.value()));

    int guardianLinksRemoved = setupRows.deleteGuardianLinks(student.id());
    int routeAssignmentsRemoved = setupRows.deleteRouteAssignments(student.id());
    int credentialsRemoved = studentRepository.deleteCredentials(student.id());

    if (!studentRepository.discard(student.id())) {
      throw new BusinessRuleViolationException(ErrorCode.STUDENT_HAS_SAFETY_RECORDS, "BR-STU-007");
    }

    Map<String, Object> before = new LinkedHashMap<>();
    before.put("admissionNo", student.admissionNo().value());
    before.put("schoolId", student.schoolId().value().toString());
    before.put("enrolmentStatus", student.enrolmentStatus().name());

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("STUDENT_DISCARDED")
            .subject("Student", student.id().value())
            .reason(trimmedReason)
            .before(before)
            .after(
                Map.of(
                    "guardianLinksRemoved", guardianLinksRemoved,
                    "routeAssignmentsRemoved", routeAssignmentsRemoved,
                    "credentialsRemoved", credentialsRemoved))
            .build());
  }

  /** A school-scoped caller discards only within their own schools; outside them, not found. */
  private static boolean inScope(AccessScope scope, Student student) {
    return scope.organizationWide() || scope.schoolIds().contains(student.schoolId().value());
  }

  private static String requireReason(String reason) {
    if (reason == null || reason.isBlank()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-STU-007", Map.of("field", "reason"));
    }
    String trimmed = reason.trim();
    if (trimmed.length() > REASON_MAX_LENGTH) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE,
          "BR-STU-007",
          Map.of("field", "reason", "maxLength", REASON_MAX_LENGTH));
    }
    return trimmed;
  }
}
