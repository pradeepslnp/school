package com.guardian.staff.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * A local wrapper, not a dependency on {@code guardian-tenancy}'s equivalent type — cross-module
 * access goes through the owning module's application layer, never its domain
 * (guardian-docs/01-product-discovery/MODULE_MAP.md, cross-module rule 1).
 */
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
