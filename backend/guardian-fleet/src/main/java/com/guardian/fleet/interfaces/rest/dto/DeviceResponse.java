package com.guardian.fleet.interfaces.rest.dto;

import com.guardian.fleet.domain.Device;
import java.time.Instant;
import java.util.UUID;

/** {@code credentialHash} never appears here — a stored secret is never returned to a client. */
public record DeviceResponse(
    UUID id,
    UUID vehicleId,
    String deviceIdentifier,
    String vendorCode,
    Instant lastSeenAt,
    boolean active) {

  public static DeviceResponse from(Device device) {
    return new DeviceResponse(
        device.id().value(),
        device.vehicleId().map(id -> id.value()).orElse(null),
        device.deviceIdentifier().value(),
        device.vendorCode(),
        device.lastSeenAt().orElse(null),
        device.active());
  }
}
