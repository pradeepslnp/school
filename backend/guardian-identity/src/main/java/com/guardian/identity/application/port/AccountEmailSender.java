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

  /**
   * Sends a password-reset one-time code to an existing account (ADR-0012). The reset flow uses a
   * short numeric code the person types back, not a link — it works across devices and email
   * clients and fits an OTP-familiar market.
   *
   * @param code the 6-digit code — the only place it leaves the server
   * @param validFor how long the code stays usable, so the message can say so
   */
  void sendPasswordResetCode(String email, String firstName, String code, Duration validFor);

  /**
   * Sends a one-time sign-in code to an administrator who chose "email me a code" instead of a
   * password (IAM-001, ADR-0012).
   *
   * @param code the 6-digit code — the only place it leaves the server
   * @param validFor how long the code stays usable, so the message can say so
   */
  void sendLoginCode(String email, String firstName, String code, Duration validFor);

  /**
   * Tells a person their password has just changed — the out-of-band signal that catches an
   * unauthorised reset, sent on every password change (OWASP).
   */
  void sendPasswordChangedNotice(String email, String firstName);
}
