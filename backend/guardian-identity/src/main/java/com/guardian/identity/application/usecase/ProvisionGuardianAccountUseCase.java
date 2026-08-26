package com.guardian.identity.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.command.ProvisionGuardianAccountCommand;
import com.guardian.identity.application.port.RoleProvisioningPort;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.RoleId;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Gives a guardian (parent) a working sign-in the moment they are added to a child, so the phone
 * number an administrator enters during enrolment is immediately a phone the parent can request an
 * OTP against and read their child's journey with (features GRD-001, IAM-002).
 *
 * <p>Deliberately separate from {@link ProvisionStaffAccountUseCase}, mirroring it rather than
 * sharing it — the two provision different roles and must write different audit actions, and the
 * codebase keeps {@code CreateAdministrativeUserUseCase} separate from staff provisioning for the
 * same reason. What they share is the shape, and the reason for it:
 *
 * <p><b>Idempotent by phone, within the tenant.</b> {@code users} has no uniqueness constraint on
 * phone, so a person who is already a driver here — or already a guardian of another child here —
 * must reuse that one account rather than get a second one. This is not merely tidy: {@code
 * auth_resolve_phone} refuses to sign anyone in whose phone resolves to more than one account, so a
 * duplicate account would silently make the parent unable to log in at all (BR-IAM-003). Siblings
 * therefore share a single guardian login, which is exactly right — it is one parent.
 *
 * <p>A freshly created user is {@link com.guardian.identity.domain.UserStatus#ACTIVE} and carries
 * no credential of any kind; the phone-OTP path issues a code on demand (see {@link
 * RequestOtpUseCase}), so no password or pre-seeded OTP credential is created here — provisioning
 * the user and granting the role is the whole of what makes the login work.
 */
@Service
public class ProvisionGuardianAccountUseCase {

  private static final String GUARDIAN_ROLE_CODE = "GUARDIAN";
  private static final String GUARDIAN_ROLE_NAME = "Guardian";

  private final UserRepository users;
  private final RoleProvisioningPort roleProvisioning;
  private final AuditPort auditPort;

  public ProvisionGuardianAccountUseCase(
      UserRepository users, RoleProvisioningPort roleProvisioning, AuditPort auditPort) {
    this.users = users;
    this.roleProvisioning = roleProvisioning;
    this.auditPort = auditPort;
  }

  public UserId execute(ProvisionGuardianAccountCommand command) {
    TenantId tenantId = TenantContext.require();
    PhoneNumber phone = parsePhone(command.phone());

    User user =
        users
            .findByPhone(phone)
            .orElseGet(
                () ->
                    users.create(
                        User.create(
                            UserId.of(UUID.randomUUID()),
                            phone,
                            command.firstName(),
                            command.lastName(),
                            "en")));

    RoleId roleId =
        roleProvisioning.findOrCreateSystemRole(tenantId, GUARDIAN_ROLE_CODE, GUARDIAN_ROLE_NAME);
    roleProvisioning.grantIfMissing(tenantId, user.id(), roleId);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("GUARDIAN_ACCOUNT_PROVISIONED")
            .subject("User", user.id().value())
            .after(
                Map.<String, Object>of("roleCode", GUARDIAN_ROLE_CODE, "phone", phone.masked()))
            .build());

    return user.id();
  }

  /**
   * Stricter than a name field's validation — this is the point the number becomes a sign-in
   * credential, so it must actually be one. A malformed value is a caller mistake (the console form
   * should have refused it first), reported as such rather than swallowed.
   */
  private static PhoneNumber parsePhone(String raw) {
    try {
      return PhoneNumber.of(raw);
    } catch (IllegalArgumentException e) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT, "BR-GRD-001", Map.of("field", "phone"));
    }
  }
}
