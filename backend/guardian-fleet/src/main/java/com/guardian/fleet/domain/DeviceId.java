package com.guardian.fleet.domain;

import java.util.Objects;
import java.util.UUID;

public record DeviceId(UUID value) {

  public DeviceId {
    Objects.requireNonNull(value, "value");
  }

  public static DeviceId of(UUID value) {
    return new DeviceId(value);
  }

  public static DeviceId generate() {
    return new DeviceId(UUID.randomUUID());
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
