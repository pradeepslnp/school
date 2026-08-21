package com.guardian.identity.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Identifies one issued session. Appears in the access token as {@code sessionId} so a revoked
 * session can be recognised before its token expires (BR-IAM-007).
 */
public record SessionId(UUID value) {

  public SessionId {
    Objects.requireNonNull(value, "value");
  }

  public static SessionId of(UUID value) {
    return new SessionId(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
