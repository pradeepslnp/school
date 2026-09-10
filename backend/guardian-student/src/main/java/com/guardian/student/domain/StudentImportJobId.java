package com.guardian.student.domain;

import java.util.Objects;
import java.util.UUID;

/** Identifier for a bulk student import (feature STU-002). */
public record StudentImportJobId(UUID value) {

  public StudentImportJobId {
    Objects.requireNonNull(value, "value");
  }

  public static StudentImportJobId of(UUID value) {
    return new StudentImportJobId(value);
  }

  public static StudentImportJobId generate() {
    return new StudentImportJobId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
