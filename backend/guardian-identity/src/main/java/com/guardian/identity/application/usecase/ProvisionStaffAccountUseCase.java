package com.guardian.identity.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.command.ProvisionStaffAccountCommand;
import com.guardian.identity.application.port.RoleProvisioningPort;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.RoleId;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Gives a newly registered driver or attendant a working sign-in (feature STF-001, completing the
 * activation path {@code transport_staff.user_id}'s own column comment calls MOD-02 and marks as
 * not yet built).
 *
 * <p>Runs under the tenant context the caller already established — unlike {@code
 * CreateOrganizationUseCase} and {@code StaffLoginUseCase}, there is no bootstrap problem here:
 * this is called from inside an authenticated {@code ORG_ADMIN}/{@code TRANSPORT_MANAGER} request
 * that is already inside its own tenant (matching {@code CreateTransportStaffUseCase}, which reads
 * {@link TenantContext#require()} the same way rather than taking a {@code
 * TenantScopedTransaction}).
 *
 * <p><b>Idempotent by phone, within the tenant.</b> If a user with this phone number already exists
 * in this tenant (perhaps a driver being re-registered, or a person who already holds another role
 * here), that account is reused and simply granted the new role rather than a second account being
 * minted — {@code users} has no uniqueness constraint on phone, so creating one unconditionally
 * would eventually let one person end up with two accounts and two role sets, which is exactly the
 * confusion {@link PhoneNumber}'s own documentation describes for guardians.
 */
@Service
public class ProvisionStaffAccountUseCase {

  private final UserRepository users;
  private final RoleProvisioningPort roleProvisioning;
  private final AuditPort auditPort;

  public ProvisionStaffAccountUseCase(
      UserRepository users, RoleProvisioningPort roleProvisioning, AuditPort auditPort) {
    this.users = users;
    this.roleProvisioning = roleProvisioning;
    this.auditPort = auditPort;
  }

  public UserId execute(ProvisionStaffAccountCommand command) {
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

    // BR-IAM-014: an account left inactive with no role — its number was once entered by mistake
    // and then corrected away — belongs to whoever holds the number. Proving that is what an OTP
    // does, so the account is reactivated under this person's name rather than blocking the number.
    boolean reactivated =
        user.status() == UserStatus.INACTIVE && users.roleCodesOf(user.id()).isEmpty();
    if (reactivated) {
      user =
          users.save(
              user.withProfile(command.firstName(), command.lastName(), user.preferredLocale())
                  .withStatus(UserStatus.ACTIVE));
    }

    RoleId roleId =
        roleProvisioning.findOrCreateSystemRole(tenantId, command.roleCode(), command.roleName());
    roleProvisioning.grantIfMissing(tenantId, user.id(), roleId);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("STAFF_ACCOUNT_PROVISIONED")
            .subject("User", user.id().value())
            .after(
                Map.<String, Object>of(
                    "roleCode", command.roleCode(),
                    "phone", phone.masked(),
                    "accountReactivated", reactivated))
            .build());

    return user.id();
  }

  /**
   * Stricter than {@code TransportStaff.phone()}'s own validation (non-blank text only) — this is
   * the point the number becomes a sign-in credential, so it must actually be one. A malformed
   * value reaches here as a caller mistake (the console's own form should have refused it first),
   * reported as such rather than silently swallowed.
   */
  private static PhoneNumber parsePhone(String raw) {
    try {
      return PhoneNumber.of(raw);
    } catch (IllegalArgumentException e) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT, "BR-STAFF-001", Map.of("field", "phone"));
    }
  }
}
