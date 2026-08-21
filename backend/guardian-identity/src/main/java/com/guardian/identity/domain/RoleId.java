package com.guardian.identity.domain;

import java.util.Objects;
import java.util.UUID;

/** Identifies a role — a template from PERMISSION_MATRIX.md, granted per tenant. */
public record RoleId(UUID value) {

  public RoleId {
    Objects.requireNonNull(value, "value");
  }

  public static RoleId of(UUID value) {
    return new RoleId(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
