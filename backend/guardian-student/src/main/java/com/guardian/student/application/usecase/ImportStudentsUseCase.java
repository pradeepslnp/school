package com.guardian.student.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.student.application.StudentEnrolment;
import com.guardian.student.application.StudentImportCsv;
import com.guardian.student.application.StudentImportRejectedException;
import com.guardian.student.application.command.CreateStudentCommand;
import com.guardian.student.application.command.ImportStudentsCommand;
import com.guardian.student.application.port.StudentImportJobRepository;
import com.guardian.student.application.port.StudentRepository;
import com.guardian.student.domain.AdmissionNumber;
import com.guardian.student.domain.ImportRowError;
import com.guardian.student.domain.StudentImportJob;
import com.guardian.student.domain.StudentImportJobId;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Enrols every valid row of an uploaded spreadsheet (feature STU-002, screen A-12).
 *
 * <p><strong>Per-row, partial success.</strong> A single bad line does not discard the file
 * (STUDENTS_GUARDIANS_API.md): valid rows are enrolled, the rest are recorded as errors the office
 * downloads, corrects, and re-uploads. The file is refused whole only when it cannot be read at all
 * — {@link StudentImportRejectedException}.
 *
 * <p>Each enrolled student goes through {@link StudentEnrolment}, the same path the one-at-a-time
 * endpoint uses, so the uniqueness rule and the per-student audit record are identical whichever
 * way a child was added.
 *
 * <p><strong>Synchronous, with a row cap.</strong> The whole file is processed inside one request
 * and one transaction — bounded work (DEFINITION_OF_DONE.md §8). A file above {@link #MAX_ROWS} is
 * rejected with guidance to split it; lifting that limit is a future asynchronous job behind the
 * same endpoint.
 */
@Service
@BusinessRule({"BR-STU-001", "BR-STU-003", "BR-AUD-002"})
public class ImportStudentsUseCase {

  /**
   * Above this the office splits the file. A synchronous request should not hold a transaction open
   * for longer than this many enrolments take.
   */
  static final int MAX_ROWS = 5_000;

  private static final int NAME_MAX_LENGTH = 128;

  private final StudentRepository studentRepository;
  private final StudentImportJobRepository jobRepository;
  private final StudentEnrolment enrolment;
  private final AuditPort auditPort;

  public ImportStudentsUseCase(
      StudentRepository studentRepository,
      StudentImportJobRepository jobRepository,
      StudentEnrolment enrolment,
      AuditPort auditPort) {
    this.studentRepository = studentRepository;
    this.jobRepository = jobRepository;
    this.enrolment = enrolment;
    this.auditPort = auditPort;
  }

  @Transactional
  public StudentImportJob execute(ImportStudentsCommand command) {
    TenantId tenantId = TenantContext.require();

    List<StudentImportCsv.Row> rows = StudentImportCsv.parse(command.content());
    if (rows.size() > MAX_ROWS) {
      throw new StudentImportRejectedException(
          ErrorCode.STUDENT_IMPORT_TOO_MANY_ROWS,
          Map.of("maxRows", MAX_ROWS, "submittedRows", rows.size()));
    }

    List<ImportRowError> errors = new ArrayList<>();
    List<Candidate> candidates = new ArrayList<>();

    // Pass 1 — format and required-field validation, row by row. First problem found on a row is
    // the one reported: a line with three faults still only needs the operator to open it once.
    for (StudentImportCsv.Row row : rows) {
      validate(row, command)
          .ifPresentOrElse(errors::add, () -> candidates.add(toCandidate(row, command)));
    }

    // Pass 2 — the same admission number twice in one file. Neither row is enrolled: the platform
    // cannot tell which the office meant (BR-STU-003).
    rejectInFileDuplicates(candidates, errors);

    // Pass 3 — already on the roll. A read, so it belongs before any write in this transaction.
    List<Candidate> toEnrol = new ArrayList<>();
    for (Candidate candidate : candidates) {
      if (candidate.rejected) {
        continue;
      }
      if (studentRepository.existsByAdmissionNo(
          candidate.command.schoolId(), candidate.command.admissionNo())) {
        errors.add(
            ImportRowError.of(
                candidate.line,
                "admissionNo",
                ErrorCode.STUDENT_ADMISSION_NO_EXISTS.name(),
                "Admission number "
                    + candidate.command.admissionNo().value()
                    + " already exists in this school"));
      } else {
        toEnrol.add(candidate);
      }
    }

    // Pass 4 — enrol. Every remaining candidate has been checked, so a failure here is a genuine
    // race with a concurrent enrolment; it aborts the whole import rather than being swallowed,
    // because the transaction is already the unit of work.
    for (Candidate candidate : toEnrol) {
      enrolment.enrol(candidate.command);
    }

    errors.sort((a, b) -> Integer.compare(a.rowNumber(), b.rowNumber()));

    StudentImportJob job =
        StudentImportJob.completed(
            StudentImportJobId.generate(),
            tenantId,
            command.schoolId(),
            command.actorId(),
            command.actorRole(),
            command.fileName(),
            rows.size(),
            toEnrol.size(),
            errors);

    StudentImportJob saved = jobRepository.save(job);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("STUDENT_IMPORT_COMPLETED")
            .subject("StudentImportJob", saved.id().value())
            .after(summary(saved))
            .build());

    return saved;
  }

  private java.util.Optional<ImportRowError> validate(
      StudentImportCsv.Row row, ImportStudentsCommand command) {

    String admissionNo = row.get(StudentImportCsv.Column.ADMISSION_NO);
    if (admissionNo.isBlank()) {
      return java.util.Optional.of(missing(row.lineNumber(), "admissionNo"));
    }
    try {
      AdmissionNumber.of(admissionNo);
    } catch (BusinessRuleViolationException e) {
      return java.util.Optional.of(
          invalidFormat(row.lineNumber(), "admissionNo", "is not a valid admission number"));
    }

    String firstName = row.get(StudentImportCsv.Column.FIRST_NAME);
    if (firstName.isBlank()) {
      return java.util.Optional.of(missing(row.lineNumber(), "firstName"));
    }
    if (firstName.length() > NAME_MAX_LENGTH) {
      return java.util.Optional.of(
          invalidFormat(
              row.lineNumber(), "firstName", "exceeds " + NAME_MAX_LENGTH + " characters"));
    }

    String lastName = row.get(StudentImportCsv.Column.LAST_NAME);
    if (lastName.isBlank()) {
      return java.util.Optional.of(missing(row.lineNumber(), "lastName"));
    }
    if (lastName.length() > NAME_MAX_LENGTH) {
      return java.util.Optional.of(
          invalidFormat(
              row.lineNumber(), "lastName", "exceeds " + NAME_MAX_LENGTH + " characters"));
    }

    String dob = row.get(StudentImportCsv.Column.DATE_OF_BIRTH);
    if (!dob.isBlank()) {
      LocalDate parsed;
      try {
        parsed = LocalDate.parse(dob);
      } catch (DateTimeParseException e) {
        return java.util.Optional.of(
            invalidFormat(row.lineNumber(), "dateOfBirth", "must be formatted YYYY-MM-DD"));
      }
      if (!parsed.isBefore(LocalDate.now())) {
        return java.util.Optional.of(
            invalidFormat(row.lineNumber(), "dateOfBirth", "must be in the past"));
      }
    }

    if (parseTransportEligible(row.get(StudentImportCsv.Column.TRANSPORT_ELIGIBLE)) == null) {
      return java.util.Optional.of(
          invalidFormat(
              row.lineNumber(), "transportEligible", "must be true or false (or left blank)"));
    }

    return java.util.Optional.empty();
  }

  private Candidate toCandidate(StudentImportCsv.Row row, ImportStudentsCommand command) {
    String dob = row.get(StudentImportCsv.Column.DATE_OF_BIRTH);
    Boolean eligible = parseTransportEligible(row.get(StudentImportCsv.Column.TRANSPORT_ELIGIBLE));
    CreateStudentCommand createCommand =
        new CreateStudentCommand(
            command.schoolId(),
            null,
            null,
            AdmissionNumber.of(row.get(StudentImportCsv.Column.ADMISSION_NO)),
            row.get(StudentImportCsv.Column.FIRST_NAME),
            row.get(StudentImportCsv.Column.LAST_NAME),
            dob.isBlank() ? null : LocalDate.parse(dob),
            eligible == null || eligible,
            command.actorId(),
            command.actorRole());
    return new Candidate(row.lineNumber(), createCommand);
  }

  private static void rejectInFileDuplicates(
      List<Candidate> candidates, List<ImportRowError> errors) {
    Map<String, List<Candidate>> byAdmissionNo = new LinkedHashMap<>();
    for (Candidate candidate : candidates) {
      byAdmissionNo
          .computeIfAbsent(candidate.command.admissionNo().value(), key -> new ArrayList<>())
          .add(candidate);
    }
    for (List<Candidate> group : byAdmissionNo.values()) {
      if (group.size() < 2) {
        continue;
      }
      Set<Integer> lines = new java.util.TreeSet<>();
      group.forEach(candidate -> lines.add(candidate.line));
      for (Candidate candidate : group) {
        candidate.rejected = true;
        errors.add(
            ImportRowError.of(
                candidate.line,
                "admissionNo",
                ErrorCode.STUDENT_IMPORT_DUPLICATE_ROW.name(),
                "Admission number "
                    + candidate.command.admissionNo().value()
                    + " appears on lines "
                    + lines));
      }
    }
  }

  /**
   * {@code null} means the value could not be understood. A blank value returns {@code TRUE} — a
   * student is enrolled to be transported unless somebody says otherwise, the same default {@code
   * CreateStudentRequest} applies to the single-student form.
   */
  private static Boolean parseTransportEligible(String raw) {
    String value = raw == null ? "" : raw.trim().toLowerCase(Locale.ROOT);
    return switch (value) {
      case "", "true", "yes", "y", "1" -> Boolean.TRUE;
      case "false", "no", "n", "0" -> Boolean.FALSE;
      default -> null;
    };
  }

  private static ImportRowError missing(int line, String field) {
    return ImportRowError.of(
        line,
        field,
        ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING.name(),
        capitalise(field) + " is required");
  }

  private static ImportRowError invalidFormat(int line, String field, String issue) {
    return ImportRowError.of(
        line, field, ErrorCode.VALIDATION_INVALID_FORMAT.name(), capitalise(field) + " " + issue);
  }

  private static String capitalise(String field) {
    return Character.toUpperCase(field.charAt(0)) + field.substring(1);
  }

  private static Map<String, Object> summary(StudentImportJob job) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("schoolId", job.schoolId().toString());
    values.put("fileName", job.fileName());
    values.put("totalRows", String.valueOf(job.totalRows()));
    values.put("successCount", String.valueOf(job.successCount()));
    values.put("errorCount", String.valueOf(job.errorCount()));
    return values;
  }

  private static final class Candidate {
    private final int line;
    private final CreateStudentCommand command;
    private boolean rejected;

    private Candidate(int line, CreateStudentCommand command) {
      this.line = line;
      this.command = command;
    }
  }
}
