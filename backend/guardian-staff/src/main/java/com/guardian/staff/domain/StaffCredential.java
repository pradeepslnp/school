package com.guardian.staff.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * A licence or certification held by a staff member (BR-STAFF-001 🔴).
 *
 * <p>{@code credentialType} and {@code credentialClass} come from region reference data, not a code
 * enum (ADR-0007) — the same reasoning as {@code guardian-fleet}'s {@code VehicleDocument}.
 */
public final class StaffCredential {

  private final StaffCredentialId id;
  private final TenantId tenantId;
  private final StaffId staffId;
  private final String credentialType;
  private final String credentialNumber;
  private final String credentialClass;
  private final LocalDate issuedOn;
  private final LocalDate expiresOn;
  private final boolean mandatory;
  private final String fileRef;
  private final long version;

  public StaffCredential(
      StaffCredentialId id,
      TenantId tenantId,
      StaffId staffId,
      String credentialType,
      String credentialNumber,
      String credentialClass,
      LocalDate issuedOn,
      LocalDate expiresOn,
      boolean mandatory,
      String fileRef,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.staffId = Objects.requireNonNull(staffId, "staffId");
    this.credentialType = requireText(credentialType, "credentialType");
    this.credentialNumber = credentialNumber;
    this.credentialClass = credentialClass;
    this.issuedOn = issuedOn;
    this.expiresOn = Objects.requireNonNull(expiresOn, "expiresOn");
    this.mandatory = mandatory;
    this.fileRef = fileRef;
    this.version = version;

    if (issuedOn != null && !expiresOn.isAfter(issuedOn)) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE, "BR-STAFF-001", Map.of("field", "expiresOn"));
    }
  }

  public static StaffCredential create(
      TenantId tenantId,
      StaffId staffId,
      String credentialType,
      String credentialNumber,
      String credentialClass,
      LocalDate issuedOn,
      LocalDate expiresOn,
      boolean mandatory,
      String fileRef) {
    return new StaffCredential(
        StaffCredentialId.generate(),
        tenantId,
        staffId,
        credentialType,
        credentialNumber,
        credentialClass,
        issuedOn,
        expiresOn,
        mandatory,
        fileRef,
        0L);
  }

  /** BR-STAFF-001 🔴 — the check trip-start eligibility ultimately depends on. */
  public boolean isExpired(LocalDate asOf) {
    return expiresOn.isBefore(asOf);
  }

  /** BR-STAFF-001 🔴: does this credential authorise the given licence class? */
  public boolean coversClass(String requiredClass) {
    return credentialClass != null && credentialClass.equalsIgnoreCase(requiredClass);
  }

  private static String requireText(String value, String field) {
    Objects.requireNonNull(value, field);
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-STAFF-001", Map.of("field", field));
    }
    return trimmed;
  }

  public StaffCredentialId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public StaffId staffId() {
    return staffId;
  }

  public String credentialType() {
    return credentialType;
  }

  public Optional<String> credentialNumber() {
    return Optional.ofNullable(credentialNumber);
  }

  public Optional<String> credentialClass() {
    return Optional.ofNullable(credentialClass);
  }

  public Optional<LocalDate> issuedOn() {
    return Optional.ofNullable(issuedOn);
  }

  public LocalDate expiresOn() {
    return expiresOn;
  }

  public boolean mandatory() {
    return mandatory;
  }

  public Optional<String> fileRef() {
    return Optional.ofNullable(fileRef);
  }

  public long version() {
    return version;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof StaffCredential credential && id.equals(credential.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "StaffCredential[" + id + ", " + credentialType + "]";
  }
}
