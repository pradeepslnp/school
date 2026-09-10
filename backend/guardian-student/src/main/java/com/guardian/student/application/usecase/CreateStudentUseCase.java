package com.guardian.student.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.student.application.StudentEnrolment;
import com.guardian.student.application.command.CreateStudentCommand;
import com.guardian.student.domain.Student;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Enrols a single student (feature STU-001).
 *
 * <p>The enrolment itself — the uniqueness check, the save, and the audit record — lives in {@link
 * StudentEnrolment}, shared with the bulk import so the two paths cannot diverge. This use case is
 * the transaction boundary for the one-at-a-time endpoint and nothing more.
 */
@Service
@BusinessRule({"BR-STU-001", "BR-STU-003", "BR-AUD-002"})
public class CreateStudentUseCase {

  private final StudentEnrolment enrolment;

  public CreateStudentUseCase(StudentEnrolment enrolment) {
    this.enrolment = enrolment;
  }

  @Transactional
  public Student execute(CreateStudentCommand command) {
    return enrolment.enrol(command);
  }
}
