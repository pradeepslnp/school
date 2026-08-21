package com.guardian.student.interfaces.rest.dto;

import com.guardian.student.domain.BranchId;
import com.guardian.student.domain.Student;
import com.guardian.student.domain.StudentClassId;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Wire format for a student.
 *
 * <p>{@code photoRef} is <strong>not</strong> exposed. It is a storage key, and returning it would
 * invite a client to build a URL from it — the exact thing MOD-03-04-students-guardians.md refuses,
 * because a guessable photo URL for a child is a safety problem. Photos are served through {@code
 * GET /students/{id}/photo}, which checks permission and scope on every request.
 */
public record StudentResponse(
    UUID id,
    UUID schoolId,
    UUID branchId,
    UUID studentClassId,
    String admissionNo,
    String firstName,
    String lastName,
    LocalDate dateOfBirth,
    String enrolmentStatus,
    boolean transportEligible,
    boolean hasPhoto) {

  public static StudentResponse from(Student student) {
    return new StudentResponse(
        student.id().value(),
        student.schoolId().value(),
        student.branchId().map(BranchId::value).orElse(null),
        student.studentClassId().map(StudentClassId::value).orElse(null),
        student.admissionNo().value(),
        student.firstName(),
        student.lastName(),
        student.dateOfBirth().orElse(null),
        student.enrolmentStatus().name(),
        student.transportEligible(),
        student.photoRef().isPresent());
  }
}
