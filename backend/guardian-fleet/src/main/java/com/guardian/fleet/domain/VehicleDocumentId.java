package com.guardian.fleet.domain;

import java.util.Objects;
import java.util.UUID;

public record VehicleDocumentId(UUID value) {

  public VehicleDocumentId {
    Objects.requireNonNull(value, "value");
  }

  public static VehicleDocumentId of(UUID value) {
    return new VehicleDocumentId(value);
  }

  public static VehicleDocumentId generate() {
    return new VehicleDocumentId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
