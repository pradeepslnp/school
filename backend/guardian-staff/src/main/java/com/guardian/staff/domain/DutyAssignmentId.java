package com.guardian.staff.domain;

import java.util.Objects;
import java.util.UUID;

public record DutyAssignmentId(UUID value) {

  public DutyAssignmentId {
    Objects.requireNonNull(value, "value");
  }

  public static DutyAssignmentId of(UUID value) {
    return new DutyAssignmentId(value);
  }

  public static DutyAssignmentId generate() {
    return new DutyAssignmentId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
