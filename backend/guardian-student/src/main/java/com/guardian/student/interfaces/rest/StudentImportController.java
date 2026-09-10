package com.guardian.student.interfaces.rest;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.rest.RawResponseBody;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.student.application.StudentImportRejectedException;
import com.guardian.student.application.command.ImportStudentsCommand;
import com.guardian.student.application.usecase.ExportStudentImportErrorsUseCase;
import com.guardian.student.application.usecase.GetStudentImportUseCase;
import com.guardian.student.application.usecase.ImportStudentsUseCase;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.StudentImportJob;
import com.guardian.student.domain.StudentImportJobId;
import com.guardian.student.interfaces.rest.dto.StudentImportJobResponse;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Bulk student import (feature STU-002, screen A-12). See
 * guardian-docs/04-api/STUDENTS_GUARDIANS_API.md §POST /students/import.
 *
 * <p>Separate from {@link StudentController} because the workload is different in kind — a
 * multipart upload, a per-row result, a downloadable error file — not because it is a different
 * resource. All three paths sit under {@code /students/import}.
 *
 * <p>This layer only translates: read the upload, call one use case, map the result. The per-row
 * validation, the enrolment, and the audit records are the use case's.
 */
@RestController
@RequestMapping("/api/v1/students/import")
public class StudentImportController {

  /**
   * Matches {@code student_import_jobs.file_name VARCHAR(255)} (V17). The name is a label shown
   * back to the operator, never used as a path.
   */
  private static final int FILE_NAME_MAX_LENGTH = 255;

  private final ImportStudentsUseCase importStudents;
  private final GetStudentImportUseCase getImport;
  private final ExportStudentImportErrorsUseCase exportErrors;

  public StudentImportController(
      ImportStudentsUseCase importStudents,
      GetStudentImportUseCase getImport,
      ExportStudentImportErrorsUseCase exportErrors) {
    this.importStudents = importStudents;
    this.getImport = getImport;
    this.exportErrors = exportErrors;
  }

  /**
   * {@code POST /students/import} — enrols every valid row of {@code file} into {@code schoolId}
   * (STU-002, {@code PERM-STUDENT-IMPORT}).
   *
   * <p>{@code 202 Accepted}: the response models a job even though processing is synchronous today,
   * so a later move to background processing does not change the contract.
   */
  @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @RequiresPermission("PERM-STUDENT-IMPORT")
  public ResponseEntity<StudentImportJobResponse> importFile(
      @RequestParam("schoolId") UUID schoolId,
      @RequestParam("file") MultipartFile file,
      CurrentActor actor) {

    if (file == null || file.isEmpty()) {
      throw new StudentImportRejectedException(
          ErrorCode.STUDENT_IMPORT_FILE_EMPTY, Map.of("field", "file"));
    }

    ImportStudentsCommand command =
        new ImportStudentsCommand(
            SchoolId.of(schoolId),
            trimFileName(file.getOriginalFilename()),
            readBytes(file),
            actor.userId(),
            actor.role());

    StudentImportJob job = importStudents.execute(command);

    return ResponseEntity.accepted().body(StudentImportJobResponse.from(job));
  }

  /** {@code GET /students/import/{jobId}} — the result of an earlier upload (STU-002). */
  @GetMapping("/{jobId}")
  @RequiresPermission("PERM-STUDENT-IMPORT")
  public StudentImportJobResponse getById(@PathVariable UUID jobId) {
    return StudentImportJobResponse.from(getImport.byId(StudentImportJobId.of(jobId)));
  }

  /**
   * {@code GET /students/import/{jobId}/errors.csv} — the failed rows, in a file the office fixes
   * and re-uploads (STU-002, {@code PERM-STUDENT-IMPORT}).
   *
   * <p>A data export: audited with a record count by the use case (BR-RPT-002 🔴).
   */
  @GetMapping(value = "/{jobId}/errors.csv", produces = "text/csv")
  @RequiresPermission("PERM-STUDENT-IMPORT")
  @RawResponseBody(
      reason = "a CSV download the office re-uploads; the JSON envelope would corrupt it")
  public ResponseEntity<String> downloadErrors(@PathVariable UUID jobId, CurrentActor actor) {
    String csv = exportErrors.toCsv(StudentImportJobId.of(jobId), actor);
    return ResponseEntity.ok()
        .header(
            HttpHeaders.CONTENT_DISPOSITION,
            "attachment; filename=\"student-import-" + jobId + "-errors.csv\"")
        .contentType(MediaType.parseMediaType("text/csv; charset=utf-8"))
        .body(csv);
  }

  private static byte[] readBytes(MultipartFile file) {
    try {
      return file.getBytes();
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }

  private static String trimFileName(String original) {
    if (original == null || original.isBlank()) {
      return "upload.csv";
    }
    String trimmed = original.trim();
    return trimmed.length() > FILE_NAME_MAX_LENGTH
        ? trimmed.substring(0, FILE_NAME_MAX_LENGTH)
        : trimmed;
  }
}
