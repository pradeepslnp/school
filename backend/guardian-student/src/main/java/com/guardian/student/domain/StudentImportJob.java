package com.guardian.student.domain;

import com.guardian.common.tenant.TenantId;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * The record of one bulk student upload (feature STU-002, screen A-12).
 *
 * <p>Immutable, and append-only in storage: a job describes what a past import did, and the office
 * re-reads it to see which lines still need fixing. It is created once, when the file has finished
 * processing — there is no half-written job.
 *
 * <p>Contains no framework annotations — an architecture test fails the build if Spring or JPA
 * types reach this package.
 */
public final class StudentImportJob {

  private final StudentImportJobId id;
  private final TenantId tenantId;
  private final SchoolId schoolId;
  private final UUID uploadedBy;
  private final String uploadedRole;
  private final String fileName;
  private final StudentImportStatus status;
  private final int totalRows;
  private final int successCount;
  private final int errorCount;
  private final List<ImportRowError> rowErrors;
  private final Instant createdAt;
  private final Instant completedAt;

  public StudentImportJob(
      StudentImportJobId id,
      TenantId tenantId,
      SchoolId schoolId,
      UUID uploadedBy,
      String uploadedRole,
      String fileName,
      StudentImportStatus status,
      int totalRows,
      int successCount,
      int errorCount,
      List<ImportRowError> rowErrors,
      Instant createdAt,
      Instant completedAt) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.schoolId = Objects.requireNonNull(schoolId, "schoolId");
    this.uploadedBy = Objects.requireNonNull(uploadedBy, "uploadedBy");
    this.uploadedRole = Objects.requireNonNull(uploadedRole, "uploadedRole");
    this.fileName = Objects.requireNonNull(fileName, "fileName");
    this.status = Objects.requireNonNull(status, "status");
    if (successCount < 0 || errorCount < 0 || totalRows < 0) {
      throw new IllegalArgumentException("counts cannot be negative");
    }
    if (successCount + errorCount > totalRows) {
      throw new IllegalArgumentException(
          "success + error ("
              + (successCount + errorCount)
              + ") exceeds total ("
              + totalRows
              + ")");
    }
    this.totalRows = totalRows;
    this.successCount = successCount;
    this.errorCount = errorCount;
    this.rowErrors = List.copyOf(Objects.requireNonNull(rowErrors, "rowErrors"));
    this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
    this.completedAt = Objects.requireNonNull(completedAt, "completedAt");
  }

  /**
   * A file that was parsed and processed. {@code importedCount} is how many rows were enrolled; the
   * errors are every row that was not. {@code dataRowCount} counts the lines below the header, so
   * {@code importedCount + errors.size()} equals it.
   */
  public static StudentImportJob completed(
      StudentImportJobId id,
      TenantId tenantId,
      SchoolId schoolId,
      UUID uploadedBy,
      String uploadedRole,
      String fileName,
      int dataRowCount,
      int importedCount,
      List<ImportRowError> errors) {
    return new StudentImportJob(
        id,
        tenantId,
        schoolId,
        uploadedBy,
        uploadedRole,
        fileName,
        StudentImportStatus.COMPLETED,
        dataRowCount,
        importedCount,
        errors.size(),
        errors,
        Instant.now(),
        Instant.now());
  }

  /**
   * A file that could not be processed at all — empty, unreadable, or carrying an unknown column.
   * Nothing was enrolled. The single {@link ImportRowError} explains why, on row 2 by convention so
   * it satisfies the row numbering invariant while pointing at the start of the data.
   */
  public static StudentImportJob failed(
      StudentImportJobId id,
      TenantId tenantId,
      SchoolId schoolId,
      UUID uploadedBy,
      String uploadedRole,
      String fileName,
      ImportRowError reason) {
    return new StudentImportJob(
        id,
        tenantId,
        schoolId,
        uploadedBy,
        uploadedRole,
        fileName,
        StudentImportStatus.FAILED,
        0,
        0,
        0,
        List.of(reason),
        Instant.now(),
        Instant.now());
  }

  public StudentImportJobId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public SchoolId schoolId() {
    return schoolId;
  }

  public UUID uploadedBy() {
    return uploadedBy;
  }

  public String uploadedRole() {
    return uploadedRole;
  }

  public String fileName() {
    return fileName;
  }

  public StudentImportStatus status() {
    return status;
  }

  public int totalRows() {
    return totalRows;
  }

  public int successCount() {
    return successCount;
  }

  public int errorCount() {
    return errorCount;
  }

  public List<ImportRowError> rowErrors() {
    return rowErrors;
  }

  public Instant createdAt() {
    return createdAt;
  }

  public Instant completedAt() {
    return completedAt;
  }
}
