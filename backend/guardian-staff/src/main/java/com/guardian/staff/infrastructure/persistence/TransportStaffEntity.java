package com.guardian.staff.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * JPA mapping for {@code transport_staff}. Never leaves this package — an architecture test fails
 * the build if a controller returns one (guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md).
 */
@Entity
@Table(name = "transport_staff")
public class TransportStaffEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "school_id", nullable = false, updatable = false)
  private UUID schoolId;

  @Column(name = "user_id")
  private UUID userId;

  @Column(name = "staff_type", nullable = false, length = 24, updatable = false)
  private String staffType;

  @Column(name = "employee_code", length = 64)
  private String employeeCode;

  @Column(name = "first_name", nullable = false, length = 128)
  private String firstName;

  @Column(name = "last_name", nullable = false, length = 128)
  private String lastName;

  @Column(name = "phone", nullable = false, length = 32)
  private String phone;

  @Column(name = "photo_ref")
  private String photoRef;

  @Column(name = "vendor_name")
  private String vendorName;

  @Column(name = "verification_status", nullable = false, length = 24)
  private String verificationStatus;

  @Column(name = "verified_until")
  private LocalDate verifiedUntil;

  @Column(name = "is_active", nullable = false)
  private boolean active;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected TransportStaffEntity() {
    // required by JPA
  }

  TransportStaffEntity(
      UUID id,
      UUID tenantId,
      UUID schoolId,
      UUID userId,
      String staffType,
      String employeeCode,
      String firstName,
      String lastName,
      String phone,
      String photoRef,
      String vendorName,
      String verificationStatus,
      LocalDate verifiedUntil,
      boolean active,
      long version) {
    this.id = id;
    this.tenantId = tenantId;
    this.schoolId = schoolId;
    this.userId = userId;
    this.staffType = staffType;
    this.employeeCode = employeeCode;
    this.firstName = firstName;
    this.lastName = lastName;
    this.phone = phone;
    this.photoRef = photoRef;
    this.vendorName = vendorName;
    this.verificationStatus = verificationStatus;
    this.verifiedUntil = verifiedUntil;
    this.active = active;
    this.version = version;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  void applyMutableState(
      UUID userId,
      String firstName,
      String lastName,
      String phone,
      String verificationStatus,
      LocalDate verifiedUntil,
      boolean active) {
    this.userId = userId;
    this.firstName = firstName;
    this.lastName = lastName;
    this.phone = phone;
    this.verificationStatus = verificationStatus;
    this.verifiedUntil = verifiedUntil;
    this.active = active;
    this.updatedAt = Instant.now();
  }

  UUID getId() {
    return id;
  }

  UUID getTenantId() {
    return tenantId;
  }

  UUID getSchoolId() {
    return schoolId;
  }

  UUID getUserId() {
    return userId;
  }

  String getStaffType() {
    return staffType;
  }

  String getEmployeeCode() {
    return employeeCode;
  }

  String getFirstName() {
    return firstName;
  }

  String getLastName() {
    return lastName;
  }

  String getPhone() {
    return phone;
  }

  String getPhotoRef() {
    return photoRef;
  }

  String getVendorName() {
    return vendorName;
  }

  String getVerificationStatus() {
    return verificationStatus;
  }

  LocalDate getVerifiedUntil() {
    return verifiedUntil;
  }

  boolean isActive() {
    return active;
  }

  long getVersion() {
    return version;
  }
}
