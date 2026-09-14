package com.guardian.identity.application.result;

import java.util.List;

/**
 * What a successful sign-in or refresh hands back.
 *
 * <p>{@code refreshToken} is the only moment the raw value exists outside the client — the server
 * keeps a hash. It must not be logged, and it is not present in {@link #toString()}.
 *
 * @param expiresInSeconds the access token's lifetime, not an absolute time. The client's clock may
 *     be wrong; the interval is still trustworthy.
 */
public record IssuedSession(
    String accessToken, String refreshToken, long expiresInSeconds, AuthenticatedUserView user) {

  /**
   * The user, as the signing-in client needs them.
   *
   * <p>{@code roles} and {@code scopes} are here <strong>for UI affordances only</strong> —
   * deciding which tabs to render, and which organization/school to pre-select on a scoped screen.
   * Neither is ever trusted for authorisation: every request re-resolves permission and scope
   * server-side (BR-IAM-001, BR-IAM-004, BR-IAM-006). The parent app deliberately does not even
   * model either field.
   *
   * <p>{@code organizationId} — the organization the account belongs to — gets the same
   * affordance-only treatment. It differs from an {@code ORG} scope: a {@code SUPER_ADMIN} holds no
   * organization scope yet still belongs to one, and the admin console uses this to withhold
   * Suspend on it (BR-TEN-006), which the server refuses regardless.
   */
  public record AuthenticatedUserView(
      String id,
      String organizationId,
      String firstName,
      String lastName,
      String preferredLocale,
      List<String> roles,
      List<ScopeView> scopes) {}

  /** One {@code {level, refId}} pair — {@code PLATFORM}/{@code ORG} carry a null {@code refId}. */
  public record ScopeView(String level, String refId) {}

  @Override
  public String toString() {
    return "IssuedSession[user=" + user.id() + ", expiresIn=" + expiresInSeconds + "]";
  }
}
