package com.guardian.staff.application.command;

import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffType;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.staff.application.usecase.CreateTransportStaffUseCase} (STF-001).
 */
public record CreateTransportStaffCommand(
    SchoolId schoolId,
    StaffType staffType,
    String employeeCode,
    String firstName,
    String lastName,
    String phone,
    String vendorName,
    UUID actorId,
    String actorRole) {

  public CreateTransportStaffCommand {
    Objects.requireNonNull(schoolId, "schoolId");
    Objects.requireNonNull(staffType, "staffType");
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
    Objects.requireNonNull(phone, "phone");
  }
}
