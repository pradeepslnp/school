package com.guardian.identity.interfaces.rest.dto;

import com.guardian.identity.application.result.IssuedSession;
import java.util.List;

/**
 * Wire representation of an issued session, matching guardian-docs/04-api/AUTHENTICATION_API.md.
 *
 * @param expiresIn seconds, not an absolute time. The device clock may be wrong; the interval is
 *     still trustworthy, and a client that computes expiry from a server timestamp will refresh at
 *     the wrong moment on a handset whose time is off.
 */
public record SessionResponse(
    String accessToken, String refreshToken, long expiresIn, String tokenType, UserResponse user) {

  /**
   * @param roles present <strong>for UI affordances only</strong>. Never trusted for authorisation
   *     — every request re-resolves permissions server-side (BR-IAM-001, BR-IAM-004). The parent
   *     app deliberately does not model this field at all.
   */
  public record UserResponse(
      String id, String firstName, String lastName, String preferredLocale, List<String> roles) {}

  public static SessionResponse from(IssuedSession issued) {
    return new SessionResponse(
        issued.accessToken(),
        issued.refreshToken(),
        issued.expiresInSeconds(),
        "Bearer",
        new UserResponse(
            issued.user().id(),
            issued.user().firstName(),
            issued.user().lastName(),
            issued.user().preferredLocale(),
            issued.user().roles()));
  }
}
