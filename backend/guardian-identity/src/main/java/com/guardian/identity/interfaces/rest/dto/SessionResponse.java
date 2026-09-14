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
   * @param scopes same affordance-only treatment as {@code roles} (BR-IAM-006) — the admin console
   *     uses this to pre-select an {@code ORG_ADMIN}/{@code SCHOOL_ADMIN}'s own organization or
   *     school on a scoped screen rather than making them pick it every time.
   * @param organizationId the organization the account belongs to — affordance only, like {@code
   *     roles}; see {@link IssuedSession.AuthenticatedUserView}.
   */
  public record UserResponse(
      String id,
      String organizationId,
      String firstName,
      String lastName,
      String preferredLocale,
      List<String> roles,
      List<ScopeResponse> scopes) {}

  public record ScopeResponse(String level, String refId) {

    static ScopeResponse from(IssuedSession.ScopeView scope) {
      return new ScopeResponse(scope.level(), scope.refId());
    }
  }

  public static SessionResponse from(IssuedSession issued) {
    return new SessionResponse(
        issued.accessToken(),
        issued.refreshToken(),
        issued.expiresInSeconds(),
        "Bearer",
        new UserResponse(
            issued.user().id(),
            issued.user().organizationId(),
            issued.user().firstName(),
            issued.user().lastName(),
            issued.user().preferredLocale(),
            issued.user().roles(),
            issued.user().scopes().stream().map(ScopeResponse::from).toList()));
  }
}
