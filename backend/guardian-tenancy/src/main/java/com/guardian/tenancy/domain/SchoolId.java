package com.guardian.tenancy.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Identifies a school.
 *
 * <p>A wrapper rather than a bare UUID so the compiler catches argument transposition. In a domain
 * with a dozen UUID-keyed entities this matters: swapping a student and a stop in a boarding call
 * produces a plausible-looking, wrong safety record.
 */
public record SchoolId(UUID value) {

  public SchoolId {
    Objects.requireNonNull(value, "value");
  }

  public static SchoolId of(UUID value) {
    return new SchoolId(value);
  }

  public static SchoolId generate() {
    return new SchoolId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
