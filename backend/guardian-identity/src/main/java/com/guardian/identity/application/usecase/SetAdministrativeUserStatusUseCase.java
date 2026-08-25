package com.guardian.identity.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
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
 * Deactivates or reactivates an administrative account ({@code PERM-USER-DEACTIVATE}, screen
 * A-43). One class for both directions — the matrix has no separate reactivate permission, and
 * the two are the same write with a different target {@link UserStatus}.
 *
 * <p>Deactivating does not, itself, revoke the person's live sessions — {@code PERM-SESSION-REVOKE}
 * is a separate permission in PERMISSION_MATRIX.md for a reason (an admin might want to end a
 * session without deactivating the account, or vice versa), and that screen is not built yet. This
 * is flagged rather than silently assumed: a deactivated user's *next* sign-in attempt is refused
 * ({@code UserStatus.canAuthenticate}), but a token issued before deactivation remains valid until
 * it naturally expires (fifteen minutes, {@code AUTHENTICATION_API.md}).
 */
@Service
public class SetAdministrativeUserStatusUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final UserScopeRepository userScopes;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public SetAdministrativeUserStatusUseCase(
      UserRepository users,
      UserScopeRepository userScopes,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.users = users;
    this.userScopes = userScopes;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public AdministrativeUserView execute(
      UUID organizationId, UUID userId, UserStatus targetStatus, UUID actorId, String actorRole) {

    if (!SUPER_ADMIN.equals(actorRole)) {
      TenantId callerTenant = TenantContext.require();
      if (!callerTenant.value().equals(organizationId)) {
        throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "organization", organizationId);
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
            .orElseThrow(() -> new ResourceNotFoundException(ErrorCode.USER_NOT_FOUND, "user", userId));

    User saved = users.save(existing.withStatus(targetStatus));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantId.of(organizationId))
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action(targetStatus == UserStatus.ACTIVE ? "USER_REACTIVATED" : "USER_DEACTIVATED")
            .subject("User", userId)
            .after(Map.<String, Object>of("status", targetStatus.name()))
            .build());

    return new AdministrativeUserView(
        saved, users.roleCodesOf(saved.id()), userScopes.findByUser(saved.id()));
  }
}
