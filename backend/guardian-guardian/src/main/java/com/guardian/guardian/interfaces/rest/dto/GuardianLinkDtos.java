package com.guardian.guardian.interfaces.rest.dto;

import com.guardian.guardian.application.port.GuardianRepository.StudentGuardian;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Wire types for the student-enrolment guardian panel (A-11). Grouped in one file because request
 * and response are two halves of one contract.
 *
 * <p>Shape follows guardian-docs/04-api/STUDENTS_GUARDIANS_API.md § Guardian–Student Links, with
 * the guardian's own identifying details (name, phone, email) folded into the same request: in this
 * console a parent is created and linked in one step, so the caller sends both together rather than
 * creating a guardian and then referencing its id.
 */
public final class GuardianLinkDtos {

  private GuardianLinkDtos() {}

  /**
   * {@code POST /students/{studentId}/guardians}.
   *
   * <p>The rights are {@link Boolean} rather than primitive so "omitted" is distinguishable from
   * "false": an omitted {@code canView}/{@code canReceiveNotifications} defaults to {@code true} and
   * an omitted {@code canAuthoriseHandover}/{@code canDeclareAbsence}/{@code isPrimary} to {@code
   * false}, matching the schema's own column defaults. The console form always sends explicit
   * values; the defaulting protects a direct API caller from accidentally creating a parent who
   * cannot even see their child.
   */
  public record AddGuardianRequest(
      @NotBlank @Size(max = 128) String firstName,
      @NotBlank @Size(max = 128) String lastName,
      @NotBlank @Size(max = 32) String phone,
      @Email @Size(max = 255) String email,
      @NotBlank @Size(max = 32) String relationshipType,
      Boolean canView,
      Boolean canReceiveNotifications,
      Boolean canAuthoriseHandover,
      Boolean canDeclareAbsence,
      Boolean isPrimary) {

    public boolean canViewOrDefault() {
      return canView == null || canView;
    }

    public boolean canReceiveNotificationsOrDefault() {
      return canReceiveNotifications == null || canReceiveNotifications;
    }

    public boolean canAuthoriseHandoverOrDefault() {
      return canAuthoriseHandover != null && canAuthoriseHandover;
    }

    public boolean canDeclareAbsenceOrDefault() {
      return canDeclareAbsence != null && canDeclareAbsence;
    }

    public boolean isPrimaryOrDefault() {
      return isPrimary != null && isPrimary;
    }
  }

  /** One guardian of a student, as the enrolment screen reads it. */
  public record GuardianResponse(
      UUID linkId,
      UUID guardianId,
      String firstName,
      String lastName,
      String phone,
      String email,
      String relationshipType,
      boolean canView,
      boolean canReceiveNotifications,
      boolean canAuthoriseHandover,
      boolean canDeclareAbsence,
      boolean isPrimary,
      boolean hasLogin) {

    public static GuardianResponse from(StudentGuardian guardian) {
      return new GuardianResponse(
          guardian.linkId(),
          guardian.guardianId(),
          guardian.firstName(),
          guardian.lastName(),
          guardian.phone(),
          guardian.email(),
          guardian.relationshipType(),
          guardian.canView(),
          guardian.canReceiveNotifications(),
          guardian.canAuthoriseHandover(),
          guardian.canDeclareAbsence(),
          guardian.isPrimary(),
          guardian.hasLogin());
    }
  }
}
