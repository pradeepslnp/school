package com.guardian.staff.domain;

import java.util.Objects;
import java.util.UUID;

public record StaffId(UUID value) {

  public StaffId {
    Objects.requireNonNull(value, "value");
  }

  public static StaffId of(UUID value) {
    return new StaffId(value);
  }

  public static StaffId generate() {
    return new StaffId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
