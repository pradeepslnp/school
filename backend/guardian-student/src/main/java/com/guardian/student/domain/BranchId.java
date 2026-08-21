package com.guardian.student.domain;

import java.util.Objects;
import java.util.UUID;

public record BranchId(UUID value) {

  public BranchId {
    Objects.requireNonNull(value, "value");
  }

  public static BranchId of(UUID value) {
    return new BranchId(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
