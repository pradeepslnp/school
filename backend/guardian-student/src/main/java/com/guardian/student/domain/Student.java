package com.guardian.student.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * A child on a school's roll (MOD-03).
 *
 * <p>Immutable: state changes return new instances. Contains no framework annotations of any kind —
 * an architecture test fails the build if Spring, JPA, or Jackson types reach this package.
 *
 * <p><strong>There is no delete.</strong> BR-STU-005: safety records — boarding events, handovers,
 * incidents — reference a student and outlive their enrolment. {@link #withdraw()} moves the record
 * out of transport without removing the subject those records are about.
 */
public final class Student {

  private final StudentId id;
  private final TenantId tenantId;
  private final SchoolId schoolId;
  private final BranchId branchId;
  private final StudentClassId studentClassId;
  private final AdmissionNumber admissionNo;
  private final String firstName;
  private final String lastName;
  private final LocalDate dateOfBirth;
  private final String photoRef;
  private final EnrolmentStatus enrolmentStatus;
  private final boolean transportEligible;
  private final long version;

  public Student(
      StudentId id,
      TenantId tenantId,
      SchoolId schoolId,
      BranchId branchId,
      StudentClassId studentClassId,
      AdmissionNumber admissionNo,
      String firstName,
      String lastName,
      LocalDate dateOfBirth,
      String photoRef,
      EnrolmentStatus enrolmentStatus,
      boolean transportEligible,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    // BR-STU-001: a student belongs to exactly one school at a time. Not nullable, and there is
    // no setter — moving a child between schools is a transfer (STU-005), not an edit.
    this.schoolId = Objects.requireNonNull(schoolId, "schoolId");
    // Null means school-wide rather than unassigned (BR-TEN-005).
    this.branchId = branchId;
    this.studentClassId = studentClassId;
    this.admissionNo = Objects.requireNonNull(admissionNo, "admissionNo");
    this.firstName = requireText(firstName, "firstName");
    this.lastName = requireText(lastName, "lastName");
    this.dateOfBirth = dateOfBirth;
    this.photoRef = photoRef;
    this.enrolmentStatus = Objects.requireNonNull(enrolmentStatus, "enrolmentStatus");
    this.transportEligible = transportEligible;
    this.version = version;
  }

  /** Enrols a new student, active from the moment they exist (feature STU-001). */
  public static Student create(
      TenantId tenantId,
      SchoolId schoolId,
      BranchId branchId,
      StudentClassId studentClassId,
      AdmissionNumber admissionNo,
      String firstName,
      String lastName,
      LocalDate dateOfBirth,
      boolean transportEligible) {
    return new Student(
        StudentId.generate(),
        tenantId,
        schoolId,
        branchId,
        studentClassId,
        admissionNo,
        firstName,
        lastName,
        dateOfBirth,
        null,
        EnrolmentStatus.ACTIVE,
        transportEligible,
        0L);
  }

  /**
   * Corrects the details the office maintains.
   *
   * <p>{@code schoolId} and {@code admissionNo} are absent on purpose. Changing a school is a
   * transfer with its own rule (BR-STU-006, clears route assignments); changing an admission number
   * would break every safety record that cites it.
   */
  public Student updateDetails(
      String newFirstName,
      String newLastName,
      LocalDate newDateOfBirth,
      BranchId newBranchId,
      StudentClassId newStudentClassId,
      boolean newTransportEligible) {
    return new Student(
        id,
        tenantId,
        schoolId,
        newBranchId,
        newStudentClassId,
        admissionNo,
        requireText(newFirstName, "firstName"),
        requireText(newLastName, "lastName"),
        newDateOfBirth,
        photoRef,
        enrolmentStatus,
        newTransportEligible,
        version);
  }

  /**
   * Takes the student off the roll (feature STU-004, BR-STU-005).
   *
   * <p>Also clears {@code transportEligible}: a withdrawn student who stayed transport-eligible
   * would still be offered by any screen that filters on eligibility alone.
   */
  public Student withdraw() {
    return new Student(
        id,
        tenantId,
        schoolId,
        branchId,
        studentClassId,
        admissionNo,
        firstName,
        lastName,
        dateOfBirth,
        photoRef,
        EnrolmentStatus.WITHDRAWN,
        false,
        version);
  }

  /** Attaches a stored photo (feature STU-006). The reference is a storage key, never a URL. */
  public Student withPhotoRef(String newPhotoRef) {
    return new Student(
        id,
        tenantId,
        schoolId,
        branchId,
        studentClassId,
        admissionNo,
        firstName,
        lastName,
        dateOfBirth,
        Objects.requireNonNull(newPhotoRef, "photoRef"),
        enrolmentStatus,
        transportEligible,
        version);
  }

  /**
   * BR-STU-004: may this student be put on a route or a manifest?
   *
   * <p>Two conditions, not one — an active student whose family has opted out of transport is on
   * the roll but not on the bus.
   */
  public boolean isAssignable() {
    return enrolmentStatus.allowsTransport() && transportEligible;
  }

  public StudentId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public SchoolId schoolId() {
    return schoolId;
  }

  public Optional<BranchId> branchId() {
    return Optional.ofNullable(branchId);
  }

  public Optional<StudentClassId> studentClassId() {
    return Optional.ofNullable(studentClassId);
  }

  public AdmissionNumber admissionNo() {
    return admissionNo;
  }

  public String firstName() {
    return firstName;
  }

  public String lastName() {
    return lastName;
  }

  public Optional<LocalDate> dateOfBirth() {
    return Optional.ofNullable(dateOfBirth);
  }

  public Optional<String> photoRef() {
    return Optional.ofNullable(photoRef);
  }

  public EnrolmentStatus enrolmentStatus() {
    return enrolmentStatus;
  }

  public boolean transportEligible() {
    return transportEligible;
  }

  public long version() {
    return version;
  }

  private static String requireText(String value, String field) {
    Objects.requireNonNull(value, field);
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-STU-001", Map.of("field", field));
    }
    return trimmed;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof Student student && id.equals(student.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  /**
   * Identifiers only. A student's name is child personal data and must not reach a log line
   * (DEFINITION_OF_DONE.md §6) — {@code toString} is exactly how it would get there by accident.
   */
  @Override
  public String toString() {
    return "Student[" + id + ", " + admissionNo + "]";
  }
}
