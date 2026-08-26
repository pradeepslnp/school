package com.guardian.guardian.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantContext;
import com.guardian.guardian.application.port.GuardianAccountProvisioningPort;
import com.guardian.guardian.application.port.GuardianRepository;
import com.guardian.guardian.application.port.GuardianRepository.StudentGuardian;
import com.guardian.guardian.domain.Guardian;
import com.guardian.guardian.domain.GuardianStudentLink;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Adds a parent to a child during enrolment (feature GRD-001, screen A-11) — the operation the
 * whole safety model turns on, because it is what makes "who may collect this child" true rather
 * than assumed.
 *
 * <p>Three things happen in one transaction, and the order matters:
 *
 * <ol>
 *   <li><b>The login is provisioned first.</b> The parent's phone becomes a working sign-in
 *       immediately (or an existing account for that phone in this tenant is reused — one parent,
 *       one login, however many children). This is why an administrator typing a parent's number is
 *       all it takes for that parent to open the app and see their child.
 *   <li><b>The guardian record is found-or-created</b> for that login, so a parent already on file
 *       for a sibling is not duplicated.
 *   <li><b>The link is written</b> with the explicit rights this relationship carries.
 * </ol>
 *
 * <p>All in one {@code @Transactional}: a guardian the platform believes it created but cannot sign
 * in as, or a login with no link to the child it was created for, are both worse than refusing the
 * operation, so any failure rolls the whole thing back — the same reasoning {@code
 * CreateTransportStaffUseCase} applies to a half-registered driver.
 *
 * <p>Rights default the way the schema does (view and notifications on, handover and absence off) —
 * that defaulting is applied at the edge before this use case is called, so a caller that says
 * nothing still gets a parent who can at least see and be told about their child, and never one who
 * can silently authorise a handover.
 */
@Service
public class AddGuardianToStudentUseCase {

  private final GuardianAccountProvisioningPort accountProvisioning;
  private final GuardianRepository guardians;
  private final AuditPort auditPort;

  public AddGuardianToStudentUseCase(
      GuardianAccountProvisioningPort accountProvisioning,
      GuardianRepository guardians,
      AuditPort auditPort) {
    this.accountProvisioning = accountProvisioning;
    this.guardians = guardians;
    this.auditPort = auditPort;
  }

  @Transactional
  @BusinessRule({"BR-GRD-001", "BR-IAM-002"})
  public StudentGuardian execute(
      UUID studentId,
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
      UUID actorUserId,
      String actorRole) {

    String cleanFirst = firstName.trim();
    String cleanLast = lastName.trim();
    String cleanPhone = phone.trim();
    String cleanEmail = blankToNull(email);

    UUID userId =
        accountProvisioning.provision(cleanPhone, cleanFirst, cleanLast, actorUserId, actorRole);

    Guardian guardian =
        guardians
            .findByUserId(userId)
            .orElseGet(
                () ->
                    guardians.saveGuardian(
                        new Guardian(
                            null, userId, cleanFirst, cleanLast, cleanPhone, cleanEmail, true),
                        actorUserId));

    GuardianStudentLink link =
        guardians.saveLink(
            new GuardianStudentLink(
                null,
                guardian.id(),
                studentId,
                relationshipType.trim(),
                canView,
                canReceiveNotifications,
                canAuthoriseHandover,
                canDeclareAbsence,
                isPrimary,
                true),
            actorUserId);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("GUARDIAN_LINKED_TO_STUDENT")
            .subject("GuardianStudentLink", link.id())
            .after(
                Map.of(
                    "studentId", studentId.toString(),
                    "guardianId", guardian.id().toString(),
                    "relationshipType", link.relationshipType(),
                    "canAuthoriseHandover", link.canAuthoriseHandover()))
            .build());

    return new StudentGuardian(
        link.id(),
        guardian.id(),
        guardian.userId(),
        guardian.firstName(),
        guardian.lastName(),
        guardian.phone(),
        guardian.email(),
        link.relationshipType(),
        link.canView(),
        link.canReceiveNotifications(),
        link.canAuthoriseHandover(),
        link.canDeclareAbsence(),
        link.isPrimary());
  }

  private static String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }
}
