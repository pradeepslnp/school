package com.guardian.staff.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Identifies the route a duty assignment crews.
 *
 * <p>A local wrapper rather than a dependency on guardian-routes' equivalent type — cross-module
 * access goes through the owning module's application layer, never its domain
 * (guardian-docs/01-product-discovery/MODULE_MAP.md, cross-module rule 1).
 */
public record RouteId(UUID value) {

  public RouteId {
    Objects.requireNonNull(value, "value");
  }

  public static RouteId of(UUID value) {
    return new RouteId(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
