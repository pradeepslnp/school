package com.guardian.student.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.DataAccessPort;
import com.guardian.common.audit.DataAccessRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.student.application.port.StudentPage;
import com.guardian.student.application.port.StudentRepository;
import com.guardian.student.domain.AdmissionNumber;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.Student;
import com.guardian.student.domain.StudentId;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reads students (feature STU-001).
 *
 * <p>Unlike most read use cases in this platform, these methods are <strong>not</strong> read-only
 * transactions and they do write. BR-IAM-012 🔴 requires every non-guardian read of child personal
 * data to leave a record, and that write shares the reader's transaction — so a read whose access
 * record cannot be stored does not happen at all.
 *
 * <p>The role is passed in rather than resolved here because "is this caller a guardian?" is a fact
 * about the request, and the alternative — this layer reaching for the security context — would
 * make the use case untestable without one.
 */
@Service
@BusinessRule({"BR-IAM-012", "BR-STU-001"})
public class GetStudentUseCase {

  /** Names why the data was read, for someone reviewing the log later. */
  private static final String PURPOSE_DETAIL = "STUDENT_DETAIL";

  private static final String PURPOSE_REGISTER = "STUDENT_REGISTER";

  private static final String ROLE_GUARDIAN = "GUARDIAN";

  private final StudentRepository studentRepository;
  private final DataAccessPort dataAccessPort;

  public GetStudentUseCase(StudentRepository studentRepository, DataAccessPort dataAccessPort) {
    this.studentRepository = studentRepository;
    this.dataAccessPort = dataAccessPort;
  }

  @Transactional
  public Student byId(StudentId studentId, CurrentActor actor) {
    Student student =
        studentRepository
            .findById(studentId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STUDENT_NOT_FOUND, "Student", studentId.value()));

    if (isNonGuardian(actor)) {
      dataAccessPort.record(
          DataAccessRecord.view(
              TenantContext.require(),
              actor.userId(),
              actor.role(),
              student.id().value(),
              PURPOSE_DETAIL));
    }

    return student;
  }

  /**
   * One page of a school's register.
   *
   * @param cursor the previous page's {@code nextCursor}, or null to start
   * @param limit page size, already clamped by the caller
   */
  @Transactional
  public StudentPage bySchool(SchoolId schoolId, String cursor, int limit, CurrentActor actor) {
    AdmissionNumber after = cursor == null || cursor.isBlank() ? null : AdmissionNumber.of(cursor);
    StudentPage page = studentRepository.findBySchool(schoolId, after, limit);

    if (isNonGuardian(actor) && !page.students().isEmpty()) {
      TenantId tenantId = TenantContext.require();
      int count = page.students().size();
      List<DataAccessRecord> records =
          page.students().stream()
              .map(
                  student ->
                      DataAccessRecord.listed(
                          tenantId,
                          actor.userId(),
                          actor.role(),
                          student.id().value(),
                          count,
                          PURPOSE_REGISTER))
              .toList();
      dataAccessPort.recordAll(records);
    }

    return page;
  }

  /**
   * A guardian reading their own children is the system working as intended, and recording it would
   * bury the accesses worth reviewing. Their reads are constrained by scope instead (BR-IAM-005),
   * which is a different control with a different purpose.
   */
  private static boolean isNonGuardian(CurrentActor actor) {
    return !ROLE_GUARDIAN.equals(actor.role());
  }
}
