package com.guardian.staff.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * A driver or attendant (MOD-06).
 *
 * <p>Immutable: state changes return new instances. Contains no framework annotations of any kind —
 * an architecture test fails the build if Spring, JPA, or Jackson types reach this package
 * (guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md).
 */
public final class TransportStaff {

  private final StaffId id;
  private final TenantId tenantId;
  private final SchoolId schoolId;
  private final UserId userId;
  private final StaffType staffType;
  private final String employeeCode;
  private final String firstName;
  private final String lastName;
  private final String phone;
  private final String photoRef;
  private final String vendorName;
  private final VerificationStatus verificationStatus;
  private final LocalDate verifiedUntil;
  private final boolean active;
  private final long version;

  public TransportStaff(
      StaffId id,
      TenantId tenantId,
      SchoolId schoolId,
      UserId userId,
      StaffType staffType,
      String employeeCode,
      String firstName,
      String lastName,
      String phone,
      String photoRef,
      String vendorName,
      VerificationStatus verificationStatus,
      LocalDate verifiedUntil,
      boolean active,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.schoolId = Objects.requireNonNull(schoolId, "schoolId");
    this.userId = userId;
    this.staffType = Objects.requireNonNull(staffType, "staffType");
    this.employeeCode = employeeCode;
    this.firstName = requireText(firstName, "firstName");
    this.lastName = requireText(lastName, "lastName");
    this.phone = requireText(phone, "phone");
    this.photoRef = photoRef;
    this.vendorName = vendorName;
    this.verificationStatus = Objects.requireNonNull(verificationStatus, "verificationStatus");
    this.verifiedUntil = verifiedUntil;
    this.active = active;
    this.version = version;

    // BR-STAFF-002 🔴: a permanently-verified staff member is a verification nobody will ever
    // revisit. Re-asserted here, matching ck_staff_verified_until in the schema, so a caller
    // that never reaches the database (a unit test, a job) cannot construct one either.
    if (verificationStatus == VerificationStatus.VERIFIED && verifiedUntil == null) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING,
          "BR-STAFF-002",
          Map.of("field", "verifiedUntil"));
    }
  }

  /** Creates a new staff record, pending verification (feature STF-001). */
  public static TransportStaff create(
      TenantId tenantId,
      SchoolId schoolId,
      StaffType staffType,
      String employeeCode,
      String firstName,
      String lastName,
      String phone,
      String vendorName) {
    return new TransportStaff(
        StaffId.generate(),
        tenantId,
        schoolId,
        null,
        staffType,
        employeeCode,
        firstName,
        lastName,
        phone,
        null,
        vendorName,
        VerificationStatus.PENDING,
        null,
        true,
        0L);
  }

  /**
   * Links this staff record to the login provisioned for it (feature STF-001/MOD-02). {@code
   * userId} starts null — see this class's field documentation — and is set exactly once, right
   * after {@code CreateTransportStaffUseCase} provisions the account in the same transaction.
   */
  public TransportStaff withUserId(UserId newUserId) {
    return new TransportStaff(
        id,
        tenantId,
        schoolId,
        Objects.requireNonNull(newUserId, "userId"),
        staffType,
        employeeCode,
        firstName,
        lastName,
        phone,
        photoRef,
        vendorName,
        verificationStatus,
        verifiedUntil,
        active,
        version);
  }

  /**
   * {@code newEmployeeCode} and {@code newVendorName} may be null or blank — both are optional
   * operational labels, the same as at creation (see {@link #create}) — but {@code firstName},
   * {@code lastName}, and {@code phone} stay required, matching every other constructor here.
   * {@code staffType} is deliberately absent — see {@code UpdateTransportStaffUseCase}'s own
   * documentation for why a type change is not offered as an edit.
   */
  public TransportStaff updateDetails(
      String newFirstName,
      String newLastName,
      String newPhone,
      String newEmployeeCode,
      String newVendorName) {
    return new TransportStaff(
        id,
        tenantId,
        schoolId,
        userId,
        staffType,
        blankToNull(newEmployeeCode),
        requireText(newFirstName, "firstName"),
        requireText(newLastName, "lastName"),
        requireText(newPhone, "phone"),
        photoRef,
        blankToNull(newVendorName),
        verificationStatus,
        verifiedUntil,
        active,
        version);
  }

  private static String blankToNull(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }

  /** BR-STAFF-002 🔴 — {@code verifiedUntil} is required, never optional, on verification. */
  public TransportStaff verify(LocalDate newVerifiedUntil) {
    Objects.requireNonNull(newVerifiedUntil, "verifiedUntil");
    return new TransportStaff(
        id,
        tenantId,
        schoolId,
        userId,
        staffType,
        employeeCode,
        firstName,
        lastName,
        phone,
        photoRef,
        vendorName,
        VerificationStatus.VERIFIED,
        newVerifiedUntil,
        active,
        version);
  }

  public TransportStaff deactivate() {
    return new TransportStaff(
        id,
        tenantId,
        schoolId,
        userId,
        staffType,
        employeeCode,
        firstName,
        lastName,
        phone,
        photoRef,
        vendorName,
        verificationStatus,
        verifiedUntil,
        false,
        version);
  }

  /** BR-STAFF-002 🔴: verified, and the verification has not lapsed as of {@code asOf}. */
  public boolean isVerifiedAsOf(LocalDate asOf) {
    return verificationStatus == VerificationStatus.VERIFIED
        && verifiedUntil != null
        && !verifiedUntil.isBefore(asOf);
  }

  public StaffId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public SchoolId schoolId() {
    return schoolId;
  }

  public Optional<UserId> userId() {
    return Optional.ofNullable(userId);
  }

  public StaffType staffType() {
    return staffType;
  }

  public Optional<String> employeeCode() {
    return Optional.ofNullable(employeeCode);
  }

  public String firstName() {
    return firstName;
  }

  public String lastName() {
    return lastName;
  }

  public String phone() {
    return phone;
  }

  public Optional<String> photoRef() {
    return Optional.ofNullable(photoRef);
  }

  public Optional<String> vendorName() {
    return Optional.ofNullable(vendorName);
  }

  public VerificationStatus verificationStatus() {
    return verificationStatus;
  }

  public Optional<LocalDate> verifiedUntil() {
    return Optional.ofNullable(verifiedUntil);
  }

  public boolean active() {
    return active;
  }

  public long version() {
    return version;
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

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof TransportStaff staff && id.equals(staff.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "TransportStaff[" + id + ", " + staffType + "]";
  }
}
