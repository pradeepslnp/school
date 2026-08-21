package com.guardian.fleet.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Identifies the school a vehicle, document, or device belongs to.
 *
 * <p>A local wrapper rather than a dependency on {@code guardian-tenancy}'s equivalent type —
 * cross-module access goes through the owning module's application layer, never its domain
 * (guardian-docs/01-product-discovery/MODULE_MAP.md, cross-module rule 1). Both wrap the same
 * underlying identifier; each module names it in its own vocabulary.
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
