package com.guardian.identity.application.port;

import java.time.Duration;

/**
 * Delivers the account-lifecycle emails: the invitation link, the password-reset link, and the
 * notice that a password has changed (ADR-0012).
 *
 * <p>A port for the same reason {@code OtpSender} is one: the delivery mechanism is a deployment
 * decision, dev-logged until a real provider adapter ships (see {@code LoggingAccountEmailSender}),
 * and the concrete provider is per-tenant configuration under ADR-0005's {@code EmailChannel}. A use
 * case never knows how the message leaves the building.
 *
 * <p>Called <strong>after</strong> the issuing transaction commits, never inside it — a rollback
 * must not be able to leave a person holding a link the database never recorded.
 */
public interface AccountEmailSender {

  /**
   * Invites a newly-created administrator to set their password and activate their account.
   *
   * @param rawToken the un-hashed {@link com.guardian.identity.domain.LinkToken} value — the only
   *     place it leaves the server
   * @param validFor how long the link stays usable, so the message can say so
   */
  void sendInvitation(String email, String firstName, String rawToken, Duration validFor);

  /** Sends a password-reset link to an existing account. */
  void sendPasswordReset(String email, String firstName, String rawToken, Duration validFor);

  /**
   * Tells a person their password has just changed — the out-of-band signal that catches an
   * unauthorised reset, sent on every password change (OWASP).
   */
  void sendPasswordChangedNotice(String email, String firstName);
}
