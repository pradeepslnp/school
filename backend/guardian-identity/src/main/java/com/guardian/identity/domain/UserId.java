package com.guardian.identity.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Identifies a person. Distinct from a bare {@link UUID} so it cannot be passed where a session,
 * role, or student id is expected.
 */
public record UserId(UUID value) {

  public UserId {
    Objects.requireNonNull(value, "value");
  }

  public static UserId of(UUID value) {
    return new UserId(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
