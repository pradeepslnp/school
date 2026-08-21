package com.guardian.student.domain;

import java.util.Objects;
import java.util.UUID;

public record StudentClassId(UUID value) {

  public StudentClassId {
    Objects.requireNonNull(value, "value");
  }

  public static StudentClassId of(UUID value) {
    return new StudentClassId(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
