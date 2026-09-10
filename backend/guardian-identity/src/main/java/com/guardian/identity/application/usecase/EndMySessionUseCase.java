package com.guardian.identity.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.domain.Session;
import com.guardian.identity.domain.SessionId;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Ends one of the caller's own sessions — an explicit "sign out this device", or the logout of the
 * current one (feature IAM-004).
 *
 * <p>Revocation is immediate for the refresh token and bounded by the access token's remaining
 * lifetime (≤15 min, BR-IAM-007) — the same guarantee every other revocation path in this module
 * gives.
 *
 * <p>The session must belong to the caller. A caller naming a session id that is someone else's —
 * even one in the same tenant, which row-level security does not hide — gets {@code
 * SESSION_NOT_FOUND}, not a permission error: the endpoint must not confirm another person's
 * session id is real. Ending another user's session is a {@code PERM-SESSION-REVOKE} action on a
 * different path.
 *
 * <p>Only {@code revoke} is set, never {@code consumedAt}: an ordinary sign-out must stay
 * distinguishable from refresh-token theft, or every logout would come back as reuse and revoke the
 * family with a security alert (see {@link Session#revoke}).
 */
@Service
public class EndMySessionUseCase {

  /**
   * Why a session ended — recorded on the audit trail and as the session's {@code revokedReason}.
   */
  public enum Trigger {
    /** The caller logged out of the session they were calling from. */
    LOGOUT("SESSION_LOGOUT", "USER_LOGOUT"),
    /** The caller signed a specific other device out from the sessions list. */
    USER_REVOKED("SESSION_REVOKED_BY_OWNER", "REVOKED_BY_OWNER");

    private final String auditAction;
    private final String revokedReason;

    Trigger(String auditAction, String revokedReason) {
      this.auditAction = auditAction;
      this.revokedReason = revokedReason;
    }
  }

  private final SessionRepository sessions;
  private final AuditPort audit;

  public EndMySessionUseCase(SessionRepository sessions, AuditPort audit) {
    this.sessions = sessions;
    this.audit = audit;
  }

  @Transactional
  public void execute(UUID sessionId, UUID callerUserId, String actorRole, Trigger trigger) {
    if (sessionId == null) {
      // Only reachable on the logout path, and only if the access token carried no sessionId
      // claim — which a token this module issues always does. Treated as "already gone".
      throw new ResourceNotFoundException(ErrorCode.SESSION_NOT_FOUND, "session", "current");
    }

    Session session =
        sessions
            .findById(SessionId.of(sessionId))
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.SESSION_NOT_FOUND, "session", sessionId));

    if (!session.userId().value().equals(callerUserId)) {
      throw new ResourceNotFoundException(ErrorCode.SESSION_NOT_FOUND, "session", sessionId);
    }

    if (session.isRevoked()) {
      // Idempotent: signing out a device that is already signed out is not an error, and
      // re-recording it would put a misleading second event on the trail.
      return;
    }

    sessions.save(session.revoke(trigger.revokedReason, Instant.now()));

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(callerUserId, AuditRecord.ActorType.USER, actorRole)
            .action(trigger.auditAction)
            .subject("Session", sessionId)
            .after(Map.<String, Object>of("clientType", session.clientType().name()))
            .build());
  }
}
