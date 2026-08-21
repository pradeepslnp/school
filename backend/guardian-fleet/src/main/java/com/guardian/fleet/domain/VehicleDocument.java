package com.guardian.fleet.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * A compliance artefact attached to a vehicle — a fitness certificate, insurance policy, or permit
 * (BR-FLEET-002 🔴).
 *
 * <p>{@code documentType} is free-form against region reference data, not a code enum (ADR-0007).
 * Registration, fitness, insurance, and permit types differ by country; a code enum here would mean
 * a code change to onboard a new market — the exact failure ADR-0007 forbids.
 */
public final class VehicleDocument {

  private final VehicleDocumentId id;
  private final TenantId tenantId;
  private final VehicleId vehicleId;
  private final String documentType;
  private final String documentNumber;
  private final LocalDate issuedOn;
  private final LocalDate expiresOn;
  private final boolean mandatory;
  private final String fileRef;
  private final long version;

  public VehicleDocument(
      VehicleDocumentId id,
      TenantId tenantId,
      VehicleId vehicleId,
      String documentType,
      String documentNumber,
      LocalDate issuedOn,
      LocalDate expiresOn,
      boolean mandatory,
      String fileRef,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.vehicleId = Objects.requireNonNull(vehicleId, "vehicleId");
    this.documentType = requireText(documentType, "documentType");
    this.documentNumber = documentNumber;
    this.issuedOn = issuedOn;
    this.expiresOn = Objects.requireNonNull(expiresOn, "expiresOn");
    this.mandatory = mandatory;
    this.fileRef = fileRef;
    this.version = version;

    // The schema expresses the same rule as ck_vehicle_documents_dates; re-asserted here so a
    // caller that never reaches the database (a unit test, a job) cannot construct a document
    // that issues after it expires.
    if (issuedOn != null && !expiresOn.isAfter(issuedOn)) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE, "BR-FLEET-002", Map.of("field", "expiresOn"));
    }
  }

  public static VehicleDocument create(
      TenantId tenantId,
      VehicleId vehicleId,
      String documentType,
      String documentNumber,
      LocalDate issuedOn,
      LocalDate expiresOn,
      boolean mandatory,
      String fileRef) {
    return new VehicleDocument(
        VehicleDocumentId.generate(),
        tenantId,
        vehicleId,
        documentType,
        documentNumber,
        issuedOn,
        expiresOn,
        mandatory,
        fileRef,
        0L);
  }

  /** BR-FLEET-002 🔴 — the check trip-start eligibility ultimately depends on. */
  public boolean isExpired(LocalDate asOf) {
    return expiresOn.isBefore(asOf);
  }

  public boolean expiresWithin(LocalDate asOf, int days) {
    return !expiresOn.isAfter(asOf.plusDays(days));
  }

  private static String requireText(String value, String field) {
    Objects.requireNonNull(value, field);
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-FLEET-002", Map.of("field", field));
    }
    return trimmed;
  }

  public VehicleDocumentId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public VehicleId vehicleId() {
    return vehicleId;
  }

  public String documentType() {
    return documentType;
  }

  public Optional<String> documentNumber() {
    return Optional.ofNullable(documentNumber);
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
    return other instanceof VehicleDocument document && id.equals(document.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "VehicleDocument[" + id + ", " + documentType + "]";
  }
}
