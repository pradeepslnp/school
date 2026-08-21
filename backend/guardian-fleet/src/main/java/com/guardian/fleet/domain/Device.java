package com.guardian.fleet.domain;

import com.guardian.common.tenant.TenantId;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;

/**
 * A GPS tracking device, optionally assigned to a vehicle (MOD-05, ADR-0004).
 *
 * <p>At most one active device may be assigned to a vehicle at a time (BR-FLEET-004) — two devices
 * reporting for one bus would produce contradictory positions. That invariant is enforced
 * structurally by a partial unique index ({@code uq_devices_vehicle_active}) and re-checked in
 * {@link com.guardian.fleet.application.usecase.AssignDeviceToVehicleUseCase} so the failure is a
 * named business-rule error rather than a raw constraint violation surfacing to a client.
 */
public final class Device {

  private final DeviceId id;
  private final TenantId tenantId;
  private final VehicleId vehicleId;
  private final DeviceIdentifier deviceIdentifier;
  private final String vendorCode;
  private final String credentialHash;
  private final Instant lastSeenAt;
  private final boolean active;
  private final long version;

  public Device(
      DeviceId id,
      TenantId tenantId,
      VehicleId vehicleId,
      DeviceIdentifier deviceIdentifier,
      String vendorCode,
      String credentialHash,
      Instant lastSeenAt,
      boolean active,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.vehicleId = vehicleId;
    this.deviceIdentifier = Objects.requireNonNull(deviceIdentifier, "deviceIdentifier");
    this.vendorCode = Objects.requireNonNull(vendorCode, "vendorCode");
    this.credentialHash = Objects.requireNonNull(credentialHash, "credentialHash");
    this.lastSeenAt = lastSeenAt;
    this.active = active;
    this.version = version;
  }

  /** Registers a new device, unassigned to any vehicle (feature FLT-004). */
  public static Device register(
      TenantId tenantId,
      DeviceIdentifier deviceIdentifier,
      String vendorCode,
      String credentialHash) {
    return new Device(
        DeviceId.generate(),
        tenantId,
        null,
        deviceIdentifier,
        vendorCode,
        credentialHash,
        null,
        true,
        0L);
  }

  public Device assignTo(VehicleId newVehicleId) {
    return new Device(
        id,
        tenantId,
        Objects.requireNonNull(newVehicleId, "vehicleId"),
        deviceIdentifier,
        vendorCode,
        credentialHash,
        lastSeenAt,
        active,
        version);
  }

  public Device unassign() {
    return new Device(
        id,
        tenantId,
        null,
        deviceIdentifier,
        vendorCode,
        credentialHash,
        lastSeenAt,
        active,
        version);
  }

  public boolean isAssigned() {
    return vehicleId != null;
  }

  public DeviceId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public Optional<VehicleId> vehicleId() {
    return Optional.ofNullable(vehicleId);
  }

  public DeviceIdentifier deviceIdentifier() {
    return deviceIdentifier;
  }

  public String vendorCode() {
    return vendorCode;
  }

  public String credentialHash() {
    return credentialHash;
  }

  public Optional<Instant> lastSeenAt() {
    return Optional.ofNullable(lastSeenAt);
  }

  public boolean active() {
    return active;
  }

  public long version() {
    return version;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof Device device && id.equals(device.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "Device[" + id + ", " + deviceIdentifier + "]";
  }
}
