package com.guardian.guardian.interfaces.rest.dto;

import com.guardian.guardian.domain.Guardian;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Wire types for the guardian record itself, apart from any one child — {@code PATCH
 * /guardians/{id}} (GRD-001). Grouped in one file because request and response are two halves of
 * one contract, matching {@link GuardianLinkDtos}.
 */
public final class GuardianDtos {

  private GuardianDtos() {}

  /**
   * {@code PATCH /guardians/{id}}. Every field is sent: the console edits the whole record, and a
   * missing name or phone is a malformed request, not "leave unchanged". A blank {@code email}
   * clears it.
   */
  public record UpdateGuardianRequest(
      @NotBlank @Size(max = 128) String firstName,
      @NotBlank @Size(max = 128) String lastName,
      @NotBlank @Size(max = 32) String phone,
      @Email @Size(max = 255) String email) {}

  /** A guardian's own details, and whether they have a sign-in. */
  public record GuardianDetailsResponse(
      UUID id, String firstName, String lastName, String phone, String email, boolean hasLogin) {

    public static GuardianDetailsResponse from(Guardian guardian) {
      return new GuardianDetailsResponse(
          guardian.id(),
          guardian.firstName(),
          guardian.lastName(),
          guardian.phone(),
          guardian.email(),
          guardian.hasLogin());
    }
  }
}
