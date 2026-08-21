package com.guardian.staff.domain;

import java.util.Objects;
import java.util.UUID;

public record StaffCredentialId(UUID value) {

  public StaffCredentialId {
    Objects.requireNonNull(value, "value");
  }

  public static StaffCredentialId of(UUID value) {
    return new StaffCredentialId(value);
  }

  public static StaffCredentialId generate() {
    return new StaffCredentialId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
