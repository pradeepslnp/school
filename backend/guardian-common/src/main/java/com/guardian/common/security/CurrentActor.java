package com.guardian.common.security;

import java.util.Objects;
import java.util.UUID;

/**
 * The authenticated user making the current request.
 *
 * <p>Resolved server-side from the session, never from client-supplied claims (BR-IAM-001).
 *
 * <p>{@code role} is captured so audit records can store the role held <em>at the time</em>
 * (BR-AUD-003) — roles change, and a record showing today's role for last year's action is
 * misleading evidence.
 *
 * <p>{@code sessionId} is the session the presented access token was issued for (its {@code
 * sessionId} claim, ADR-0006). It lets a self-service endpoint act on "the session I am calling
 * from" — logout, or listing sessions with the current one marked — without the client naming an id
 * it could get wrong or forge. It is {@code null} only where there is no session behind the actor:
 * a system-initiated action, or a test that constructs an actor directly.
 *
 * <p>{@code homeTenantId} is the organization the account belongs to — the tenant its session was
 * issued in (the access token's verified {@code tenantId} claim). Ordinarily that is also the
 * tenant the request acts in, but not under a platform elevation (ADR-0016), where the request acts
 * in a named target organization instead. A rule about the caller's own organization — such as not
 * suspending it (BR-TEN-006) — must read this, never the ambient tenant. {@code null} under the
 * same conditions as {@code sessionId}.
 */
public record CurrentActor(UUID userId, String role, UUID sessionId, UUID homeTenantId) {

  public CurrentActor {
    Objects.requireNonNull(userId, "userId");
    Objects.requireNonNull(role, "role");
  }

  public static CurrentActor of(UUID userId, String role) {
    return new CurrentActor(userId, role, null, null);
  }

  public static CurrentActor of(UUID userId, String role, UUID sessionId, UUID homeTenantId) {
    return new CurrentActor(userId, role, sessionId, homeTenantId);
  }
}
