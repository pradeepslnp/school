package com.guardian.student.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * JPA mapping for {@code student_import_row_errors} (feature STU-002). Never leaves this package.
 *
 * <p>Append-only: one row per line that could not be enrolled, written with its job and never
 * changed (V17).
 */
@Entity
@Table(name = "student_import_row_errors")
class StudentImportRowErrorEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "job_id", nullable = false, updatable = false)
  private UUID jobId;

  @Column(name = "row_number", nullable = false, updatable = false)
  private int rowNumber;

  @Column(name = "field", length = 64, updatable = false)
  private String field;

  @Column(name = "error_code", nullable = false, length = 64, updatable = false)
  private String errorCode;

  @Column(name = "message", nullable = false, length = 500, updatable = false)
  private String message;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  protected StudentImportRowErrorEntity() {
    // required by JPA
  }

  StudentImportRowErrorEntity(
      UUID id,
      UUID tenantId,
      UUID jobId,
      int rowNumber,
      String field,
      String errorCode,
      String message,
      Instant createdAt) {
    this.id = id;
    this.tenantId = tenantId;
    this.jobId = jobId;
    this.rowNumber = rowNumber;
    this.field = field;
    this.errorCode = errorCode;
    this.message = message;
    this.createdAt = createdAt;
  }

  UUID getJobId() {
    return jobId;
  }

  int getRowNumber() {
    return rowNumber;
  }

  String getField() {
    return field;
  }

  String getErrorCode() {
    return errorCode;
  }

  String getMessage() {
    return message;
  }
}
