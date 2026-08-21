package com.guardian.staff.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * A local wrapper for the identity (MOD-02) user this staff record is linked to. Null until the
 * person's account is activated — a staff record can exist before the person has signed in once.
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
