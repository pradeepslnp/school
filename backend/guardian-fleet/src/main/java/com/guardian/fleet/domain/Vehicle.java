package com.guardian.fleet.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * A vehicle operated by, or on behalf of, a school.
 *
 * <p>Immutable: state changes return new instances. Contains no framework annotations of any kind —
 * an architecture test fails the build if Spring, JPA, or Jackson types reach this package
 * (guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md).
 */
public final class Vehicle {

  private final VehicleId id;
  private final TenantId tenantId;
  private final SchoolId schoolId;
  private final RegistrationNo registrationNo;
  private final String displayName;
  private final VehicleType vehicleType;
  private final SeatingCapacity seatingCapacity;
  private final String vendorName;
  private final VehicleStatus status;
  private final long version;

  public Vehicle(
      VehicleId id,
      TenantId tenantId,
      SchoolId schoolId,
      RegistrationNo registrationNo,
      String displayName,
      VehicleType vehicleType,
      SeatingCapacity seatingCapacity,
      String vendorName,
      VehicleStatus status,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.schoolId = Objects.requireNonNull(schoolId, "schoolId");
    this.registrationNo = Objects.requireNonNull(registrationNo, "registrationNo");
    this.displayName = requireText(displayName, "displayName");
    this.vehicleType = Objects.requireNonNull(vehicleType, "vehicleType");
    this.seatingCapacity = Objects.requireNonNull(seatingCapacity, "seatingCapacity");
    this.vendorName = vendorName;
    this.status = Objects.requireNonNull(status, "status");
    this.version = version;
  }

  /** Creates a new, active vehicle (feature FLT-001). */
  public static Vehicle create(
      TenantId tenantId,
      SchoolId schoolId,
      RegistrationNo registrationNo,
      String displayName,
      VehicleType vehicleType,
      SeatingCapacity seatingCapacity,
      String vendorName) {
    return new Vehicle(
        VehicleId.generate(),
        tenantId,
        schoolId,
        registrationNo,
        displayName,
        vehicleType,
        seatingCapacity,
        vendorName,
        VehicleStatus.ACTIVE,
        0L);
  }

  public Vehicle updateDetails(
      String newDisplayName, SeatingCapacity newSeatingCapacity, String newVendorName) {
    return new Vehicle(
        id,
        tenantId,
        schoolId,
        registrationNo,
        requireText(newDisplayName, "displayName"),
        vehicleType,
        Objects.requireNonNull(newSeatingCapacity, "seatingCapacity"),
        newVendorName,
        status,
        version);
  }

  public Vehicle changeStatus(VehicleStatus newStatus) {
    return new Vehicle(
        id,
        tenantId,
        schoolId,
        registrationNo,
        displayName,
        vehicleType,
        seatingCapacity,
        vendorName,
        Objects.requireNonNull(newStatus, "status"),
        version);
  }

  public boolean isActive() {
    return status == VehicleStatus.ACTIVE;
  }

  /**
   * BR-FLEET-002 🔴: a vehicle with an expired mandatory document may not be assigned to a trip.
   * Which documents are mandatory is region configuration; that an expired mandatory document
   * blocks assignment is not.
   *
   * <p>An in-progress trip is never interrupted by an expiry occurring mid-journey — this check
   * applies only at trip start, which is the sole caller in MOD-08.
   */
  public void assertEligibleToStart() {
    if (!isActive()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VEHICLE_NOT_ACTIVE, "BR-FLEET-001", Map.of("vehicleId", id.toString()));
    }
  }

  public VehicleId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public SchoolId schoolId() {
    return schoolId;
  }

  public RegistrationNo registrationNo() {
    return registrationNo;
  }

  public String displayName() {
    return displayName;
  }

  public VehicleType vehicleType() {
    return vehicleType;
  }

  public SeatingCapacity seatingCapacity() {
    return seatingCapacity;
  }

  public Optional<String> vendorName() {
    return Optional.ofNullable(vendorName);
  }

  public VehicleStatus status() {
    return status;
  }

  public long version() {
    return version;
  }

  private static String requireText(String value, String field) {
    Objects.requireNonNull(value, field);
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-FLEET-001", Map.of("field", field));
    }
    return trimmed;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof Vehicle vehicle && id.equals(vehicle.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "Vehicle[" + id + ", " + registrationNo + "]";
  }
}
