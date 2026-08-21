package com.guardian.routes.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Identifies the vehicle a route defaults to.
 *
 * <p>A local wrapper, matching {@link SchoolId} — guardian-fleet owns the real {@code Vehicle}
 * aggregate; this module only ever needs its id (MODULE_MAP.md cross-module rule 1).
 */
public record VehicleId(UUID value) {

  public VehicleId {
    Objects.requireNonNull(value, "value");
  }

  public static VehicleId of(UUID value) {
    return new VehicleId(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
