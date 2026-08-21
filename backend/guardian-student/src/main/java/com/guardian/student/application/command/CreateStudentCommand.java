package com.guardian.student.application.command;

import com.guardian.student.domain.AdmissionNumber;
import com.guardian.student.domain.BranchId;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.StudentClassId;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Enrol a student (feature STU-001).
 *
 * <p>Carries domain types, not wire types: parsing and format validation happen at the boundary, so
 * a use case never receives a string it still has to trust.
 */
public record CreateStudentCommand(
    SchoolId schoolId,
    BranchId branchId,
    StudentClassId studentClassId,
    AdmissionNumber admissionNo,
    String firstName,
    String lastName,
    LocalDate dateOfBirth,
    boolean transportEligible,
    UUID actorId,
    String actorRole) {

  public CreateStudentCommand {
    Objects.requireNonNull(schoolId, "schoolId");
    Objects.requireNonNull(admissionNo, "admissionNo");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
  }
}
