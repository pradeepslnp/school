package com.guardian.identity.application.usecase;

import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.application.result.SessionSummary;
import com.guardian.identity.domain.Session;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lists the caller's own sessions for the "signed-in devices" screen (feature IAM-004).
 *
 * <p>Own sessions only. The caller is the authenticated principal — there is no user id parameter,
 * because an endpoint that took one would be an authorisation surface (whose sessions may I see?)
 * and this is not that. Reviewing another person's sessions is {@code PERM-SESSION-REVOKE}
 * territory and lives on the Users screen instead.
 *
 * <p>Returns revoked and expired rows too, newest first. "This phone signed out yesterday" is
 * exactly what someone scanning for unfamiliar activity needs to see.
 */
@Service
public class ListMySessionsUseCase {

  private final SessionRepository sessions;

  public ListMySessionsUseCase(SessionRepository sessions) {
    this.sessions = sessions;
  }

  @Transactional(readOnly = true)
  public List<SessionSummary> execute(UUID callerUserId, UUID currentSessionId) {
    Instant now = Instant.now();
    SessionId current = currentSessionId == null ? null : SessionId.of(currentSessionId);

    return sessions.findByUser(UserId.of(callerUserId)).stream()
        .map(session -> toSummary(session, current, now))
        .toList();
  }

  private static SessionSummary toSummary(Session session, SessionId current, Instant now) {
    return new SessionSummary(
        session.id().value().toString(),
        session.clientType().name(),
        session.deviceIdentifier(),
        session.issuedAt(),
        session.expiresAt(),
        statusOf(session, now),
        session.id().equals(current));
  }

  private static String statusOf(Session session, Instant now) {
    if (session.isRevoked()) {
      return "REVOKED";
    }
    if (!now.isBefore(session.expiresAt())) {
      return "EXPIRED";
    }
    return "ACTIVE";
  }
}
