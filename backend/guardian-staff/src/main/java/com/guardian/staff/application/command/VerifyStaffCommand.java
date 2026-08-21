package com.guardian.staff.application.command;

import com.guardian.staff.domain.StaffId;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.staff.application.usecase.VerifyStaffUseCase} (STF-003).
 *
 * <p>{@code verificationType} and {@code referenceNumber} describe the evidence (a background
 * check, a document review) and are recorded in the audit trail — {@code transport_staff} itself
 * stores only the outcome ({@code verificationStatus}) and {@code verifiedUntil}
 * (MOD-05-06-fleet-staff.md). Verification types come from region configuration (BR-STAFF-002),
 * which is why this command does not constrain {@code verificationType} to an enum.
 */
public record VerifyStaffCommand(
    StaffId staffId,
    String verificationType,
    LocalDate verifiedUntil,
    String referenceNumber,
    UUID actorId,
    String actorRole) {

  public VerifyStaffCommand {
    Objects.requireNonNull(staffId, "staffId");
    Objects.requireNonNull(verifiedUntil, "verifiedUntil");
  }
}
