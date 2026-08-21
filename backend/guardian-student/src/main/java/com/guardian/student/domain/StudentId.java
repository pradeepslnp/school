package com.guardian.student.domain;

import java.util.Objects;
import java.util.UUID;

public record StudentId(UUID value) {

  public StudentId {
    Objects.requireNonNull(value, "value");
  }

  public static StudentId of(UUID value) {
    return new StudentId(value);
  }

  public static StudentId generate() {
    return new StudentId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
