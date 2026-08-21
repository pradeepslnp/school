package com.guardian.student.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * JPA mapping for {@code students}. Never leaves this package — an architecture test fails the
 * build if a controller returns one.
 *
 * <p>{@code tenant_id} is a plain immutable column with no Hibernate filter behind it. Isolation is
 * row-level security's job (ADR-0001); a filter here would suggest it is the application's, and the
 * two would eventually disagree.
 */
@Entity
@Table(name = "students")
public class StudentEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  /** BR-STU-001: one school at a time, and changing it is a transfer rather than an edit. */
  @Column(name = "school_id", nullable = false, updatable = false)
  private UUID schoolId;

  @Column(name = "branch_id")
  private UUID branchId;

  @Column(name = "student_class_id")
  private UUID studentClassId;

  /** Immutable: safety records cite it, so a correction would orphan their reference. */
  @Column(name = "admission_no", nullable = false, length = 64, updatable = false)
  private String admissionNo;

  @Column(name = "first_name", nullable = false, length = 128)
  private String firstName;

  @Column(name = "last_name", nullable = false, length = 128)
  private String lastName;

  @Column(name = "date_of_birth")
  private LocalDate dateOfBirth;

  @Column(name = "photo_ref")
  private String photoRef;

  @Column(name = "enrolment_status", nullable = false, length = 24)
  private String enrolmentStatus;

  @Column(name = "transport_eligible", nullable = false)
  private boolean transportEligible;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected StudentEntity() {
    // required by JPA
  }

  StudentEntity(
      UUID id,
      UUID tenantId,
      UUID schoolId,
      UUID branchId,
      UUID studentClassId,
      String admissionNo,
      String firstName,
      String lastName,
      LocalDate dateOfBirth,
      String photoRef,
      String enrolmentStatus,
      boolean transportEligible) {
    this.id = id;
    this.tenantId = tenantId;
    this.schoolId = schoolId;
    this.branchId = branchId;
    this.studentClassId = studentClassId;
    this.admissionNo = admissionNo;
    this.firstName = firstName;
    this.lastName = lastName;
    this.dateOfBirth = dateOfBirth;
    this.photoRef = photoRef;
    this.enrolmentStatus = enrolmentStatus;
    this.transportEligible = transportEligible;
    this.createdAt = Instant.now();
    this.updatedAt = this.createdAt;
  }

  /** The columns an edit may touch. School and admission number are absent by design. */
  void applyMutableState(
      UUID newBranchId,
      UUID newStudentClassId,
      String newFirstName,
      String newLastName,
      LocalDate newDateOfBirth,
      String newPhotoRef,
      String newEnrolmentStatus,
      boolean newTransportEligible) {
    this.branchId = newBranchId;
    this.studentClassId = newStudentClassId;
    this.firstName = newFirstName;
    this.lastName = newLastName;
    this.dateOfBirth = newDateOfBirth;
    this.photoRef = newPhotoRef;
    this.enrolmentStatus = newEnrolmentStatus;
    this.transportEligible = newTransportEligible;
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

  UUID getBranchId() {
    return branchId;
  }

  UUID getStudentClassId() {
    return studentClassId;
  }

  String getAdmissionNo() {
    return admissionNo;
  }

  String getFirstName() {
    return firstName;
  }

  String getLastName() {
    return lastName;
  }

  LocalDate getDateOfBirth() {
    return dateOfBirth;
  }

  String getPhotoRef() {
    return photoRef;
  }

  String getEnrolmentStatus() {
    return enrolmentStatus;
  }

  boolean isTransportEligible() {
    return transportEligible;
  }

  long getVersion() {
    return version;
  }
}
