package com.guardian.identity.application.usecase;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.AccessTokenIssuer;
import com.guardian.identity.application.port.RefreshTokenFactory;
import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.Session;
import com.guardian.identity.domain.User;
import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Service;

/**
 * Turns an authenticated person into a stored session and a pair of tokens.
 *
 * <p>Shared by sign-in and refresh so the two cannot drift. They already differ in the ways that
 * matter — a refresh rotates within an existing family, a sign-in starts a new one — and the parts
 * that must stay identical are exactly the security-relevant ones: the refresh token is stored only
 * as a hash, the access token carries no roles, and the returned roles are marked as presentation
 * data.
 *
 * <p>Must be called inside a transaction that already carries the tenant. It performs no tenant
 * resolution of its own.
 */
@Service
public class SessionFactory {

  private final SessionRepository sessions;
  private final UserRepository users;
  private final RefreshTokenFactory refreshTokens;
  private final AccessTokenIssuer accessTokens;

  public SessionFactory(
      SessionRepository sessions,
      UserRepository users,
      RefreshTokenFactory refreshTokens,
      AccessTokenIssuer accessTokens) {
    this.sessions = sessions;
    this.users = users;
    this.refreshTokens = refreshTokens;
    this.accessTokens = accessTokens;
  }

  /** Starts a new session family for a fresh sign-in. */
  public Issued startSession(
      User user, TenantId tenantId, ClientType clientType, String deviceIdentifier, Instant now) {

    String rawRefreshToken = refreshTokens.generate();
    Session session =
        sessions.save(
            Session.start(
                user.id(), clientType, refreshTokens.hash(rawRefreshToken), deviceIdentifier, now));

    return new Issued(session, complete(user, tenantId, session, rawRefreshToken));
  }

  /**
   * Rotates {@code current} into a successor and consumes it.
   *
   * <p>Both writes happen here, in one transaction. Splitting them across two would leave a window
   * with a successor issued and its predecessor still spendable — two live refresh tokens for one
   * session, which is the state reuse detection exists to recognise as theft.
   */
  public Issued rotateSession(User user, TenantId tenantId, Session current, Instant now) {
    String rawRefreshToken = refreshTokens.generate();

    Session successor = current.rotateTo(refreshTokens.hash(rawRefreshToken), now);
    sessions.save(current.consume(now));
    Session saved = sessions.save(successor);

    return new Issued(saved, complete(user, tenantId, saved, rawRefreshToken));
  }

  private IssuedSession complete(
      User user, TenantId tenantId, Session session, String rawRefreshToken) {

    AccessTokenIssuer.IssuedToken accessToken =
        accessTokens.issue(
            new AccessTokenIssuer.Claims(user.id(), tenantId, session.id(), session.clientType()));

    // Read now rather than carried from the token, so a role change takes effect on the next
    // sign-in as well as on the next request (BR-IAM-004).
    List<String> roles = users.roleCodesOf(user.id());

    return new IssuedSession(
        accessToken.value(),
        rawRefreshToken,
        accessToken.lifetime().toSeconds(),
        new IssuedSession.AuthenticatedUserView(
            user.id().value().toString(),
            user.firstName(),
            user.lastName(),
            user.preferredLocale(),
            roles));
  }

  /** The stored session alongside what the client is told about it. */
  public record Issued(Session session, IssuedSession response) {}
}
