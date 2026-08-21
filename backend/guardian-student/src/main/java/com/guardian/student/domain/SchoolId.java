package com.guardian.student.domain;

import java.util.Objects;
import java.util.UUID;

public record SchoolId(UUID value) {

  public SchoolId {
    Objects.requireNonNull(value, "value");
  }

  public static SchoolId of(UUID value) {
    return new SchoolId(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
