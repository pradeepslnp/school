package com.guardian.routes.domain;

import java.util.Objects;
import java.util.UUID;

/** Identifies a stop. A wrapper rather than a bare UUID (CODING_STANDARDS_BACKEND.md). */
public record StopId(UUID value) {

  public StopId {
    Objects.requireNonNull(value, "value");
  }

  public static StopId of(UUID value) {
    return new StopId(value);
  }

  public static StopId generate() {
    return new StopId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
