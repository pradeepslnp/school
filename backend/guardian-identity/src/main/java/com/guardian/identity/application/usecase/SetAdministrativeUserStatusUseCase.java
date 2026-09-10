package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.port.UserScopeRepository;
import com.guardian.identity.application.result.AdministrativeUserView;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Deactivates or reactivates an administrative account ({@code PERM-USER-DEACTIVATE}, screen A-43).
 * One class for both directions — the matrix has no separate reactivate permission, and the two are
 * the same write with a different target {@link UserStatus}.
 *
 * <p>Deactivating <strong>also revokes every live session the account holds</strong>, in the same
 * transaction (BR-IAM-008): the refresh tokens stop working immediately and the access tokens
 * within their ≤15-minute life (BR-IAM-007). Refresh already refuses an inactive user ({@code
 * UserStatus.canAuthenticate}, checked in {@code RefreshSessionUseCase}), so a session could not
 * outlive deactivation by more than that window anyway — but ending it now closes the window rather
 * than waiting it out, which for an account with access to children's data is the difference the
 * rule is about. Ending a session <em>without</em> deactivating is the separate {@code
 * PERM-SESSION-REVOKE} path ({@link RevokeAllUserSessionsUseCase}).
 *
 * <p>Reactivation revokes nothing — there is nothing to revoke, and the account simply becomes able
 * to sign in again.
 */
@Service
@BusinessRule("BR-IAM-008")
public class SetAdministrativeUserStatusUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final UserScopeRepository userScopes;
  private final SessionRepository sessions;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public SetAdministrativeUserStatusUseCase(
      UserRepository users,
      UserScopeRepository userScopes,
      SessionRepository sessions,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.users = users;
    this.userScopes = userScopes;
    this.sessions = sessions;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public AdministrativeUserView execute(
      UUID organizationId, UUID userId, UserStatus targetStatus, UUID actorId, String actorRole) {

    if (!SUPER_ADMIN.equals(actorRole)) {
      TenantId callerTenant = TenantContext.require();
      if (!callerTenant.value().equals(organizationId)) {
        throw new ResourceNotFoundException(
            ErrorCode.AUTH_SCOPE_DENIED, "organization", organizationId);
      }
    }

    return tenantScoped.execute(
        TenantId.of(organizationId),
        () -> applyWithin(organizationId, userId, targetStatus, actorId, actorRole));
  }

  private AdministrativeUserView applyWithin(
      UUID organizationId, UUID userId, UserStatus targetStatus, UUID actorId, String actorRole) {

    User existing =
        users
            .findById(UserId.of(userId))
            .orElseThrow(
                () -> new ResourceNotFoundException(ErrorCode.USER_NOT_FOUND, "user", userId));

    User saved = users.save(existing.withStatus(targetStatus));

    int sessionsRevoked = 0;
    if (targetStatus != UserStatus.ACTIVE) {
      sessionsRevoked = sessions.revokeAllForUser(userId, "USER_DEACTIVATED");
    }

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantId.of(organizationId))
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action(targetStatus == UserStatus.ACTIVE ? "USER_REACTIVATED" : "USER_DEACTIVATED")
            .subject("User", userId)
            .after(
                Map.<String, Object>of(
                    "status", targetStatus.name(), "sessionsRevoked", sessionsRevoked))
            .build());

    return new AdministrativeUserView(
        saved, users.roleCodesOf(saved.id()), userScopes.findByUser(saved.id()));
  }
}
