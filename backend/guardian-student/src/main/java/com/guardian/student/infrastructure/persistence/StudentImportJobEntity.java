package com.guardian.student.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * JPA mapping for {@code student_import_jobs} (feature STU-002). Never leaves this package.
 *
 * <p>No {@code @Version}: the row is inserted once, when the file has finished processing, and
 * never updated — the table has no version column and grants no UPDATE (V17).
 */
@Entity
@Table(name = "student_import_jobs")
class StudentImportJobEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "school_id", nullable = false, updatable = false)
  private UUID schoolId;

  @Column(name = "uploaded_by", nullable = false, updatable = false)
  private UUID uploadedBy;

  @Column(name = "uploaded_role", nullable = false, length = 64, updatable = false)
  private String uploadedRole;

  @Column(name = "file_name", nullable = false, length = 255, updatable = false)
  private String fileName;

  @Column(name = "status", nullable = false, length = 24, updatable = false)
  private String status;

  @Column(name = "total_rows", nullable = false, updatable = false)
  private int totalRows;

  @Column(name = "success_count", nullable = false, updatable = false)
  private int successCount;

  @Column(name = "error_count", nullable = false, updatable = false)
  private int errorCount;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "completed_at", updatable = false)
  private Instant completedAt;

  protected StudentImportJobEntity() {
    // required by JPA
  }

  StudentImportJobEntity(
      UUID id,
      UUID tenantId,
      UUID schoolId,
      UUID uploadedBy,
      String uploadedRole,
      String fileName,
      String status,
      int totalRows,
      int successCount,
      int errorCount,
      Instant createdAt,
      Instant completedAt) {
    this.id = id;
    this.tenantId = tenantId;
    this.schoolId = schoolId;
    this.uploadedBy = uploadedBy;
    this.uploadedRole = uploadedRole;
    this.fileName = fileName;
    this.status = status;
    this.totalRows = totalRows;
    this.successCount = successCount;
    this.errorCount = errorCount;
    this.createdAt = createdAt;
    this.completedAt = completedAt;
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

  UUID getUploadedBy() {
    return uploadedBy;
  }

  String getUploadedRole() {
    return uploadedRole;
  }

  String getFileName() {
    return fileName;
  }

  String getStatus() {
    return status;
  }

  int getTotalRows() {
    return totalRows;
  }

  int getSuccessCount() {
    return successCount;
  }

  int getErrorCount() {
    return errorCount;
  }

  Instant getCreatedAt() {
    return createdAt;
  }

  Instant getCompletedAt() {
    return completedAt;
  }
}
