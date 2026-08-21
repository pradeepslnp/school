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
   * <p>{@code roles} is here <strong>for UI affordances only</strong> — deciding which tabs to
   * render. It is never trusted for authorisation: every request re-resolves permissions
   * server-side (BR-IAM-001, BR-IAM-004). The parent app deliberately does not even model it.
   */
  public record AuthenticatedUserView(
      String id, String firstName, String lastName, String preferredLocale, List<String> roles) {}

  @Override
  public String toString() {
    return "IssuedSession[user=" + user.id() + ", expiresIn=" + expiresInSeconds + "]";
  }
}
