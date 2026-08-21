package com.guardian.student.application.command;

import com.guardian.student.domain.BranchId;
import com.guardian.student.domain.StudentClassId;
import com.guardian.student.domain.StudentId;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/** Correct a student's details (feature STU-001). */
public record UpdateStudentCommand(
    StudentId studentId,
    String firstName,
    String lastName,
    LocalDate dateOfBirth,
    BranchId branchId,
    StudentClassId studentClassId,
    boolean transportEligible,
    UUID actorId,
    String actorRole) {

  public UpdateStudentCommand {
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
  }
}
