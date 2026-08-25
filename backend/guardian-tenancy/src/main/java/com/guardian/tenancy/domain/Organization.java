package com.guardian.tenancy.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Map;
import java.util.Objects;

/**
 * An organization — the tenant itself (BR-TEN-001, ADR-0001).
 *
 * <p>Every other tenant-scoped record traces back to one of these; its id doubles as {@code
 * tenant_id} everywhere else in the schema. Creating one is therefore the one place in the platform
 * where a request must mint a tenant rather than operate inside one it was already given (see
 * {@link com.guardian.common.tenant.TenantScopedTransaction}).
 *
 * <p>Immutable: state changes return new instances. Contains no framework annotations of any kind;
 * an architecture test fails the build if Spring, JPA, or Jackson types reach this package
 * (ENGINEERING_PRINCIPLES.md §1).
 */
public final class Organization {

  private final OrganizationId id;
  private final OrganizationCode code;
  private final String name;
  private final String regionProfileCode;
  private final OrganizationStatus status;
  private final String contactEmail;
  private final String contactPhone;
  private final long version;

  public Organization(
      OrganizationId id,
      OrganizationCode code,
      String name,
      String regionProfileCode,
      OrganizationStatus status,
      String contactEmail,
      String contactPhone,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.code = Objects.requireNonNull(code, "code");
    this.name = requireText(name, "name");
    // Not defaulted: supplies phone-format, required-document, and retention defaults for
    // every school under this organization (ADR-0007). Guessing one would apply the wrong
    // country's rules until someone noticed.
    this.regionProfileCode = requireText(regionProfileCode, "regionProfileCode");
    this.status = Objects.requireNonNull(status, "status");
    this.contactEmail = contactEmail;
    this.contactPhone = contactPhone;
    this.version = version;
  }

  /** Creates a new, active organization. */
  public static Organization create(
      OrganizationCode code,
      String name,
      String regionProfileCode,
      String contactEmail,
      String contactPhone) {
    return new Organization(
        OrganizationId.generate(),
        code,
        name,
        regionProfileCode,
        OrganizationStatus.ACTIVE,
        contactEmail,
        contactPhone,
        0L);
  }

  /**
   * Updates the fields an operator may change after creation.
   *
   * <p>{@code code} is not a parameter: it is immutable once the organization exists (BR-TEN-007),
   * and {@code status} changes only through suspend/reactivate (BR-TEN-006, not yet built), never
   * through a general edit.
   */
  public Organization update(
      String newName, String newRegionProfileCode, String newContactEmail, String newContactPhone) {
    return new Organization(
        id,
        code,
        requireText(newName, "name"),
        requireText(newRegionProfileCode, "regionProfileCode"),
        status,
        newContactEmail,
        newContactPhone,
        version);
  }

  /**
   * Suspends this organization (BR-TEN-006): blocks user access without destroying data or
   * interrupting a trip already in progress. The carve-out for in-flight safety recording is
   * enforced where requests are authorized ({@code PermissionEnforcementInterceptor}), not
   * here — this method only tracks the status transition itself.
   *
   * <p>Idempotent: suspending an already-suspended organization returns an equivalent instance
   * rather than failing, so a retried or double-clicked request is harmless.
   *
   * @throws IllegalStateException if this organization is {@link OrganizationStatus#CLOSED}.
   *     No feature closes an organization yet, so no organization can actually hold that
   *     status today — reaching this branch would mean a bug elsewhere, not a business rule
   *     a caller can trigger.
   */
  public Organization suspend() {
    if (status == OrganizationStatus.CLOSED) {
      throw new IllegalStateException("Cannot suspend a closed organization: " + id);
    }
    if (status == OrganizationStatus.SUSPENDED) {
      return this;
    }
    return withStatus(OrganizationStatus.SUSPENDED);
  }

  /**
   * Reactivates this organization (BR-TEN-006), restoring the access suspension removed.
   *
   * <p>Idempotent: reactivating an already-active organization returns an equivalent instance
   * rather than failing, for the same double-click-safety reason as {@link #suspend()}.
   *
   * @throws IllegalStateException if this organization is {@link OrganizationStatus#CLOSED} —
   *     see {@link #suspend()}'s Javadoc for why this is a defensive guard, not a reachable
   *     business scenario today.
   */
  public Organization reactivate() {
    if (status == OrganizationStatus.CLOSED) {
      throw new IllegalStateException("Cannot reactivate a closed organization: " + id);
    }
    if (status == OrganizationStatus.ACTIVE) {
      return this;
    }
    return withStatus(OrganizationStatus.ACTIVE);
  }

  private Organization withStatus(OrganizationStatus newStatus) {
    return new Organization(
        id, code, name, regionProfileCode, newStatus, contactEmail, contactPhone, version);
  }

  private static String requireText(String value, String field) {
    Objects.requireNonNull(value, field);
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-TEN-001", Map.of("field", field));
    }
    return trimmed;
  }

  public OrganizationId id() {
    return id;
  }

  public OrganizationCode code() {
    return code;
  }

  public String name() {
    return name;
  }

  public String regionProfileCode() {
    return regionProfileCode;
  }

  public OrganizationStatus status() {
    return status;
  }

  public String contactEmail() {
    return contactEmail;
  }

  public String contactPhone() {
    return contactPhone;
  }

  public long version() {
    return version;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof Organization organization && id.equals(organization.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "Organization[" + id + ", " + code + "]";
  }
}
