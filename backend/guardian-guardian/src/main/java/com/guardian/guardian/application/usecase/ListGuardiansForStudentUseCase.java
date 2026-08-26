package com.guardian.guardian.application.usecase;

import com.guardian.guardian.application.port.GuardianRepository;
import com.guardian.guardian.application.port.GuardianRepository.StudentGuardian;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lists a student's guardians and the rights each holds, for the enrolment screen (feature GRD-002,
 * screen A-11).
 *
 * <p>Read-only and tenant-scoped by row-level security. A guardian requesting another family's
 * student never reaches here — the controller's {@code PERM-STUDENT-VIEW} and object-level scope
 * (BR-IAM-005) settle that before this runs.
 */
@Service
public class ListGuardiansForStudentUseCase {

  private final GuardianRepository guardians;

  public ListGuardiansForStudentUseCase(GuardianRepository guardians) {
    this.guardians = guardians;
  }

  @Transactional(readOnly = true)
  public List<StudentGuardian> execute(UUID studentId) {
    return guardians.findActiveForStudent(studentId);
  }
}
