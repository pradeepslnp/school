package com.guardian.student.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Wire format for enrolling a student.
 *
 * <p>Bean validation catches malformed input at the boundary; domain value objects re-check the
 * invariants they own. The duplication is intentional — the domain must remain correct when called
 * from a bulk import or a test that never passes through this DTO.
 *
 * @param branchId null means school-wide rather than unassigned (BR-TEN-005)
 * @param transportEligible defaults to true when absent: a student is enrolled to be transported
 *     unless somebody says otherwise, and requiring the flag would make the common case the verbose
 *     one.
 */
public record CreateStudentRequest(
    @NotNull UUID schoolId,
    UUID branchId,
    UUID studentClassId,
    @NotBlank @Size(max = 64) String admissionNo,
    @NotBlank @Size(max = 128) String firstName,
    @NotBlank @Size(max = 128) String lastName,
    @Past LocalDate dateOfBirth,
    Boolean transportEligible) {

  public boolean transportEligibleOrDefault() {
    return transportEligible == null || transportEligible;
  }
}
