package com.guardian.student.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.tenant.TenantContext;
import com.guardian.student.application.port.StudentImportJobRepository;
import com.guardian.student.domain.ImportRowError;
import com.guardian.student.domain.StudentImportJob;
import com.guardian.student.domain.StudentImportJobId;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Produces the downloadable "error rows" file for a bulk import (feature STU-002, screen A-12).
 *
 * <p>The office downloads this, fixes the named lines in their spreadsheet, and re-uploads a small
 * file rather than reconciling hundreds of rows by hand (STUDENTS_GUARDIANS_API.md).
 *
 * <p>This is a data export, so it is audited with a record count (BR-RPT-002 🔴) — the file carries
 * admission numbers and names of children the office is enrolling, and "who exported this, and how
 * much" must be answerable. The write shares the request's transaction: an export whose audit
 * record cannot be stored does not happen.
 */
@Service
@BusinessRule({"BR-RPT-002"})
public class ExportStudentImportErrorsUseCase {

  private final StudentImportJobRepository jobRepository;
  private final AuditPort auditPort;

  public ExportStudentImportErrorsUseCase(
      StudentImportJobRepository jobRepository, AuditPort auditPort) {
    this.jobRepository = jobRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public String toCsv(StudentImportJobId id, CurrentActor actor) {
    StudentImportJob job =
        jobRepository
            .findById(id)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STUDENT_IMPORT_NOT_FOUND, "StudentImportJob", id.value()));

    StringBuilder csv = new StringBuilder("row,field,code,message\r\n");
    for (ImportRowError error : job.rowErrors()) {
      csv.append(error.rowNumber())
          .append(',')
          .append(csvField(error.field() == null ? "" : error.field()))
          .append(',')
          .append(csvField(error.code()))
          .append(',')
          .append(csvField(error.message()))
          .append("\r\n");
    }

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actor.userId(), AuditRecord.ActorType.USER, actor.role())
            .action("STUDENT_IMPORT_ERROR_REPORT_EXPORTED")
            .subject("StudentImportJob", job.id().value())
            .after(scope(job))
            .build());

    return csv.toString();
  }

  private static Map<String, Object> scope(StudentImportJob job) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("schoolId", job.schoolId().toString());
    values.put("recordCount", String.valueOf(job.rowErrors().size()));
    return values;
  }

  /** RFC 4180: quote a field that contains a comma, quote, or newline; double any inner quote. */
  private static String csvField(String value) {
    if (value.contains(",")
        || value.contains("\"")
        || value.contains("\n")
        || value.contains("\r")) {
      return '"' + value.replace("\"", "\"\"") + '"';
    }
    return value;
  }
}
