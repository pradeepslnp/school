package com.guardian.student.interfaces.rest.dto;

import com.guardian.student.domain.ImportRowError;
import com.guardian.student.domain.StudentImportJob;
import java.util.List;
import java.util.UUID;

/**
 * Wire format for a bulk import result (feature STU-002, screen A-12).
 *
 * <p>Shape fixed by STUDENTS_GUARDIANS_API.md §POST /students/import. {@code errorReportUrl} is
 * present only when there is something to download — the console shows a "Download error rows"
 * action exactly when this is non-null.
 *
 * <p>Each {@code code} is a value from the platform error catalogue, so the console renders a row
 * error with the same localisation key it would use for that failure anywhere else (BR-CFG-005).
 */
public record StudentImportJobResponse(
    UUID jobId,
    String status,
    int totalRows,
    int successCount,
    int errorCount,
    List<RowError> errors,
    String errorReportUrl) {

  public record RowError(int row, String field, String code, String message) {

    static RowError from(ImportRowError error) {
      return new RowError(error.rowNumber(), error.field(), error.code(), error.message());
    }
  }

  public static StudentImportJobResponse from(StudentImportJob job) {
    List<RowError> errors = job.rowErrors().stream().map(RowError::from).toList();
    String errorReportUrl =
        job.errorCount() == 0 ? null : "/students/import/" + job.id().value() + "/errors.csv";
    return new StudentImportJobResponse(
        job.id().value(),
        job.status().name(),
        job.totalRows(),
        job.successCount(),
        job.errorCount(),
        errors,
        errorReportUrl);
  }
}
