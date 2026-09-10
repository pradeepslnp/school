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
import com.guardian.identity.domain.UserId;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Ends every live session a person holds, on an administrator's initiative (feature IAM-004, {@code
 * PERM-SESSION-REVOKE}; screen A-43).
 *
 * <p>Separate from deactivating the account: an administrator may want to force a re-login — a
 * shared device left signed in, a suspected shoulder-surf — without disabling the person. The
 * matrix keeps {@code PERM-SESSION-REVOKE} distinct from {@code PERM-USER-DEACTIVATE} for exactly
 * this.
 *
 * <p>Immediate for every refresh token; ≤15 minutes for the access tokens (BR-IAM-007). The blast
 * radius is audited.
 *
 * <p>Bootstraps into the target organization's tenant the same way the other {@code /users}
 * operations do — a {@code SUPER_ADMIN} acting on an organization they onboarded is not a member of
 * its tenant. The non-{@code SUPER_ADMIN} caller-boundary check runs first, against their own
 * ambient tenant.
 */
@Service
@BusinessRule("BR-IAM-007")
public class RevokeAllUserSessionsUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final SessionRepository sessions;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public RevokeAllUserSessionsUseCase(
      UserRepository users,
      SessionRepository sessions,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.users = users;
    this.sessions = sessions;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public void execute(UUID organizationId, UUID userId, UUID actorId, String actorRole) {
    if (!SUPER_ADMIN.equals(actorRole)) {
      TenantId callerTenant = TenantContext.require();
      if (!callerTenant.value().equals(organizationId)) {
        throw new ResourceNotFoundException(
            ErrorCode.AUTH_SCOPE_DENIED, "organization", organizationId);
      }
    }

    tenantScoped.execute(
        TenantId.of(organizationId),
        () -> {
          revokeWithin(organizationId, userId, actorId, actorRole);
          return null;
        });
  }

  private void revokeWithin(UUID organizationId, UUID userId, UUID actorId, String actorRole) {
    users
        .findById(UserId.of(userId))
        .orElseThrow(() -> new ResourceNotFoundException(ErrorCode.USER_NOT_FOUND, "user", userId));

    int revoked = sessions.revokeAllForUser(userId, "ADMIN_SESSION_REVOKE");

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantId.of(organizationId))
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("USER_SESSIONS_REVOKED")
            .subject("User", userId)
            .after(Map.<String, Object>of("sessionsRevoked", revoked))
            .build());
  }
}
