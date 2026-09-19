package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.RoleProvisioningPort;
import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.result.AccountReleaseOutcome;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Takes one role back from a sign-in account when the record that granted it no longer points at
 * that account — a guardian's or driver's phone was corrected, or a mistaken staff entry was
 * discarded (BR-IAM-014, ADR-0019).
 *
 * <p><strong>Every session the account holds is revoked, whatever roles remain.</strong> The usual
 * reason for a release is that the number was wrong, so whoever holds that phone may have signed in
 * with access that was never theirs. A shared account that keeps another role — a parent who was
 * wrongly also made a driver — signs in again and loses nothing it is entitled to.
 *
 * <p>An account left holding no role becomes {@link UserStatus#INACTIVE}. It is <em>never
 * deleted</em>: {@code notifications} cascade from {@code users}, and whatever was done under the
 * account must stay attributed to the number that did it. {@link ProvisionStaffAccountUseCase} and
 * {@link ProvisionGuardianAccountUseCase} reactivate such an account if its number is given a role
 * again.
 *
 * <p>Runs inside the caller's own transaction and tenant, like the provisioning use cases it pairs
 * with — a release must commit or roll back together with the relink that caused it.
 */
@Service
@BusinessRule("BR-IAM-014")
public class ReleaseAccountRoleUseCase {

  private static final String SESSION_REVOKED_REASON = "ACCOUNT_ROLE_RELEASED";

  private final UserRepository users;
  private final RoleProvisioningPort roleProvisioning;
  private final SessionRepository sessions;
  private final AuditPort auditPort;

  public ReleaseAccountRoleUseCase(
      UserRepository users,
      RoleProvisioningPort roleProvisioning,
      SessionRepository sessions,
      AuditPort auditPort) {
    this.users = users;
    this.roleProvisioning = roleProvisioning;
    this.sessions = sessions;
    this.auditPort = auditPort;
  }

  /**
   * @param reasonCode why the role is being released, e.g. {@code PHONE_CORRECTED} — recorded on
   *     the audit trail, never shown to the account holder
   */
  public AccountReleaseOutcome execute(
      UUID userId, String roleCode, String reasonCode, UUID actorId, String actorRole) {
    TenantId tenantId = TenantContext.require();

    Optional<User> found = users.findById(UserId.of(userId));
    if (found.isEmpty()) {
      return AccountReleaseOutcome.ACCOUNT_NOT_FOUND;
    }
    User user = found.get();

    roleProvisioning.revokeSystemRole(tenantId, user.id(), roleCode);
    int sessionsRevoked = sessions.revokeAllForUser(userId, SESSION_REVOKED_REASON);

    AccountReleaseOutcome outcome = AccountReleaseOutcome.ROLE_REMOVED;
    if (users.roleCodesOf(user.id()).isEmpty()) {
      users.save(user.withStatus(UserStatus.INACTIVE));
      outcome = AccountReleaseOutcome.ACCOUNT_DEACTIVATED;
    }

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("ACCOUNT_ROLE_RELEASED")
            .subject("User", userId)
            .after(
                Map.<String, Object>of(
                    "roleCode", roleCode,
                    "reason", reasonCode,
                    "outcome", outcome.name(),
                    "sessionsRevoked", sessionsRevoked))
            .build());

    return outcome;
  }
}
