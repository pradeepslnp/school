package com.guardian.fleet.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * Identifies a vehicle.
 *
 * <p>A wrapper rather than a bare UUID so the compiler catches argument transposition — in a domain
 * with a dozen UUID-keyed entities, swapping two identifiers is a defect the type system should
 * catch (guardian-docs/06-development/CODING_STANDARDS_BACKEND.md).
 */
public record VehicleId(UUID value) {

  public VehicleId {
    Objects.requireNonNull(value, "value");
  }

  public static VehicleId of(UUID value) {
    return new VehicleId(value);
  }

  public static VehicleId generate() {
    return new VehicleId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
