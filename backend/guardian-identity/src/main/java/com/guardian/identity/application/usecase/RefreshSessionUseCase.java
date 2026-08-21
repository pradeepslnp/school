package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.AuthenticationFailedException;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.SessionLocation;
import com.guardian.identity.application.port.RefreshTokenFactory;
import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.domain.Session;
import com.guardian.identity.domain.User;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Rotates a session (feature IAM-003).
 *
 * <p>The presented refresh token is consumed and a new one issued. Rotation is not an optimisation:
 * it is what makes theft detectable at all. A token that is never rotated and never reused looks
 * exactly like a token in two people's hands.
 *
 * <h2>Reuse detection</h2>
 *
 * <p>Presenting an already-consumed token means two parties hold it. Which one is presenting it now
 * cannot be determined, so the response is {@code AUTH_REFRESH_REUSE_DETECTED} and the
 * <strong>whole family is revoked</strong> — every session descended from that sign-in
 * (BR-IAM-009). The legitimate user is signed out too. In a system holding children's live
 * locations that is the correct trade, and it is why the revocation is not gentler.
 *
 * <p>The security alert this should also raise (NTF-SEC-02) is recorded as an audit event for now;
 * the notification module does not exist yet.
 */
@Service
@BusinessRule({"BR-IAM-007", "BR-IAM-009"})
public class RefreshSessionUseCase {

  private static final Logger log = LoggerFactory.getLogger(RefreshSessionUseCase.class);

  private final PreAuthenticationDirectory directory;
  private final SessionRepository sessions;
  private final UserRepository users;
  private final RefreshTokenFactory refreshTokens;
  private final SessionFactory sessionFactory;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public RefreshSessionUseCase(
      PreAuthenticationDirectory directory,
      SessionRepository sessions,
      UserRepository users,
      RefreshTokenFactory refreshTokens,
      SessionFactory sessionFactory,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.directory = directory;
    this.sessions = sessions;
    this.users = users;
    this.refreshTokens = refreshTokens;
    this.sessionFactory = sessionFactory;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public IssuedSession execute(String presentedToken) {
    Instant now = Instant.now();

    if (presentedToken == null || presentedToken.isBlank()) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_TOKEN_MISSING);
    }

    // Looked up by hash: the raw token is never compared against anything stored, because
    // nothing stored is the raw token.
    Optional<SessionLocation> location =
        directory.findSessionByRefreshTokenHash(refreshTokens.hash(presentedToken));

    if (location.isEmpty()) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_TOKEN_INVALID);
    }

    SessionLocation found = location.get();

    // Same shape as VerifyOtpUseCase and for the same reason: revoking a family is a write,
    // and throwing from inside the transaction would roll back the revocation that reuse
    // detection exists to perform.
    Outcome outcome = tenantScoped.execute(found.tenantId(), () -> rotateWithin(found, now));

    return switch (outcome) {
      case Outcome.Refused refused -> throw new AuthenticationFailedException(refused.code());
      case Outcome.Succeeded succeeded -> succeeded.session();
    };
  }

  private Outcome rotateWithin(SessionLocation location, Instant now) {
    Optional<Session> found = sessions.findById(location.sessionId());
    if (found.isEmpty()) {
      return Outcome.refused(ErrorCode.AUTH_TOKEN_INVALID);
    }

    Session session = found.get();

    switch (session.refreshVerdictAt(now)) {
      case REUSE_DETECTED -> {
        return revokeFamilyAndRefuse(session, location, now);
      }
      case REVOKED -> {
        return Outcome.refused(ErrorCode.AUTH_SESSION_REVOKED);
      }
      case EXPIRED -> {
        return Outcome.refused(ErrorCode.AUTH_TOKEN_EXPIRED);
      }
      case ACCEPTABLE -> {
        // fall through
      }
    }

    Optional<User> user = users.findById(session.userId());
    if (user.isEmpty() || !user.get().status().canAuthenticate()) {
      // Covers BR-IAM-008: a deactivated staff member's refresh stops working immediately,
      // without waiting for a job to walk their sessions.
      return Outcome.refused(ErrorCode.AUTH_SESSION_REVOKED);
    }

    SessionFactory.Issued issued =
        sessionFactory.rotateSession(user.get(), location.tenantId(), session, now);

    return Outcome.succeeded(issued.response());
  }

  private Outcome revokeFamilyAndRefuse(Session session, SessionLocation location, Instant now) {
    int revoked = sessions.revokeFamily(session.familyId(), "REFRESH_REUSE_DETECTED", now);

    log.warn(
        "Refresh token reuse detected for session family {}; revoked {} sessions (BR-IAM-009)",
        session.familyId(),
        revoked);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(location.tenantId())
            .actor(session.userId().value(), AuditRecord.ActorType.SYSTEM, null)
            .action("AUTH_REFRESH_REUSE_DETECTED")
            .subject("Session", session.id().value())
            .after(
                Map.<String, Object>of(
                    "familyId", session.familyId().toString(), "sessionsRevoked", revoked))
            .build());

    return Outcome.refused(ErrorCode.AUTH_REFRESH_REUSE_DETECTED);
  }

  private sealed interface Outcome {

    record Succeeded(IssuedSession session) implements Outcome {}

    record Refused(ErrorCode code) implements Outcome {}

    static Outcome succeeded(IssuedSession session) {
      return new Succeeded(session);
    }

    static Outcome refused(ErrorCode code) {
      return new Refused(code);
    }
  }
}
