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
 */
public record CurrentActor(UUID userId, String role) {

  public CurrentActor {
    Objects.requireNonNull(userId, "userId");
    Objects.requireNonNull(role, "role");
  }

  public static CurrentActor of(UUID userId, String role) {
    return new CurrentActor(userId, role);
  }
}
