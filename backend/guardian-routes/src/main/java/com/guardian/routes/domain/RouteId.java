package com.guardian.routes.domain;

import java.util.Objects;
import java.util.UUID;

/** Identifies a route. A wrapper rather than a bare UUID (CODING_STANDARDS_BACKEND.md). */
public record RouteId(UUID value) {

  public RouteId {
    Objects.requireNonNull(value, "value");
  }

  public static RouteId of(UUID value) {
    return new RouteId(value);
  }

  public static RouteId generate() {
    return new RouteId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
