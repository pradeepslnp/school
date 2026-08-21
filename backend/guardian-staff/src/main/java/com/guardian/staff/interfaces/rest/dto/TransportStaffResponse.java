package com.guardian.staff.interfaces.rest.dto;

import com.guardian.staff.domain.TransportStaff;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Wire representation of a staff member. A domain object is never serialised directly to a client.
 */
public record TransportStaffResponse(
    UUID id,
    UUID schoolId,
    UUID userId,
    String staffType,
    String employeeCode,
    String firstName,
    String lastName,
    String phone,
    String vendorName,
    String verificationStatus,
    LocalDate verifiedUntil,
    boolean active) {

  public static TransportStaffResponse from(TransportStaff staff) {
    return new TransportStaffResponse(
        staff.id().value(),
        staff.schoolId().value(),
        staff.userId().map(id -> id.value()).orElse(null),
        staff.staffType().name(),
        staff.employeeCode().orElse(null),
        staff.firstName(),
        staff.lastName(),
        staff.phone(),
        staff.vendorName().orElse(null),
        staff.verificationStatus().name(),
        staff.verifiedUntil().orElse(null),
        staff.active());
  }
}
