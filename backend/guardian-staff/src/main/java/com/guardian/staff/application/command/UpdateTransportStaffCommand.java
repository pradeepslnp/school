package com.guardian.staff.application.command;

import com.guardian.staff.domain.StaffId;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.staff.application.usecase.UpdateTransportStaffUseCase} (STF-001).
 */
public record UpdateTransportStaffCommand(
    StaffId staffId,
    String firstName,
    String lastName,
    String phone,
    // Optional, matching CreateTransportStaffCommand — no requireNonNull for either.
    String employeeCode,
    String vendorName,
    UUID actorId,
    String actorRole) {

  public UpdateTransportStaffCommand {
    Objects.requireNonNull(staffId, "staffId");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
    Objects.requireNonNull(phone, "phone");
  }
}
