package com.guardian.fleet.application.command;

import java.util.Objects;
import java.util.UUID;

/**
 * Input to {@link com.guardian.fleet.application.usecase.RegisterDeviceUseCase} (FLT-004).
 *
 * <p>Devices are explicitly registered by a fleet manager — never inferred from an ingested
 * position report (BR-FLEET-006). {@code credentialSecret} is the plaintext value issued to the
 * device at provisioning time; only its hash is persisted.
 */
public record RegisterDeviceCommand(
    String deviceIdentifier,
    String vendorCode,
    String credentialSecret,
    UUID actorId,
    String actorRole) {

  public RegisterDeviceCommand {
    Objects.requireNonNull(deviceIdentifier, "deviceIdentifier");
    Objects.requireNonNull(vendorCode, "vendorCode");
    Objects.requireNonNull(credentialSecret, "credentialSecret");
  }
}
