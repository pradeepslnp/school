package com.guardian.student.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Wire format for correcting a student's details.
 *
 * <p>{@code schoolId} and {@code admissionNo} are absent deliberately — see {@code
 * Student.updateDetails} for why neither is an edit.
 */
public record UpdateStudentRequest(
    UUID branchId,
    UUID studentClassId,
    @NotBlank @Size(max = 128) String firstName,
    @NotBlank @Size(max = 128) String lastName,
    @Past LocalDate dateOfBirth,
    Boolean transportEligible) {

  public boolean transportEligibleOrDefault() {
    return transportEligible == null || transportEligible;
  }
}
