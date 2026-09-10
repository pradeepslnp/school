package com.guardian.guardian.interfaces.rest.dto;

import com.guardian.guardian.domain.CustodyRestriction;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

/**
 * Wire types for screen A-14. One file: request and response are two halves of one contract.
 *
 * <p>Shape follows guardian-docs/04-api/STUDENTS_GUARDIANS_API.md § Custody Restrictions.
 */
public final class CustodyRestrictionDtos {

  private CustodyRestrictionDtos() {}

  /**
   * {@code POST /students/{studentId}/custody-restrictions}.
   *
   * <p>Exactly one of {@code restrictedGuardianId} / {@code restrictedPersonName} — the domain and
   * {@code ck_custody_subject} both refuse anything else, and the use case turns "neither or both"
   * into {@code CUSTODY_RESTRICTION_SUBJECT_REQUIRED}. {@code effectiveFrom} defaults to now.
   */
  public record RecordRequest(
      UUID restrictedGuardianId,
      @Size(max = 255) String restrictedPersonName,
      @NotBlank String restrictionType,
      @NotBlank @Size(max = 4000) String reason,
      Instant effectiveFrom,
      Instant effectiveUntil) {}

  /**
   * One restriction as the console reads it.
   *
   * <p>This type is returned only to {@code PERM-CUSTODY-RESTRICTION-MANAGE} holders and must never
   * reach a guardian-facing surface (BR-GRD-008 🔴) — there is no parent-app mapping of it
   * anywhere.
   */
  public record CustodyRestrictionResponse(
      UUID id,
      UUID studentId,
      UUID restrictedGuardianId,
      String restrictedPersonName,
      String restrictionType,
      String reason,
      Instant effectiveFrom,
      Instant effectiveUntil,
      boolean active) {

    public static CustodyRestrictionResponse from(CustodyRestriction restriction) {
      return new CustodyRestrictionResponse(
          restriction.id(),
          restriction.studentId(),
          restriction.restrictedGuardianId(),
          restriction.restrictedPersonName(),
          restriction.type().name(),
          restriction.reason(),
          restriction.effectiveFrom(),
          restriction.effectiveUntil(),
          restriction.active());
    }
  }
}
