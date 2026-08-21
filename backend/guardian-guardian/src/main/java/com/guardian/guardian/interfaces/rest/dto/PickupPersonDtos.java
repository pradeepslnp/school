package com.guardian.guardian.interfaces.rest.dto;

import com.guardian.guardian.domain.PickupPerson;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

/**
 * Wire types for P-07. Grouped in one file because they are two halves of one contract and reading
 * them apart is harder than reading them together.
 *
 * <p>Shape follows guardian-docs/04-api/STUDENTS_GUARDIANS_API.md § Authorised Pickup Persons.
 */
public final class PickupPersonDtos {

  private PickupPersonDtos() {}

  /**
   * {@code POST /students/{studentId}/pickup-persons}.
   *
   * <p>{@code validUntil} is {@code @NotNull} — the API contract says required, and the domain
   * refuses a nomination without it. Both, deliberately: validation gives the caller a useful
   * message, the domain guarantees the invariant holds however the object was built.
   */
  public record NominateRequest(
      @NotBlank @Size(max = 255) String fullName,
      @NotBlank @Size(max = 32) String phone,
      @Size(max = 255) String relationshipNote,
      @NotNull Instant validFrom,
      @NotNull Instant validUntil) {}

  /** One nomination as the app reads it. */
  public record PickupPersonResponse(
      UUID id,
      UUID studentId,
      String fullName,
      String phone,
      String relationshipNote,
      Instant validFrom,
      Instant validUntil) {

    public static PickupPersonResponse from(PickupPerson person) {
      return new PickupPersonResponse(
          person.id(),
          person.studentId(),
          person.fullName(),
          person.phone(),
          person.relationshipNote(),
          person.validFrom(),
          person.validUntil());
    }
  }
}
