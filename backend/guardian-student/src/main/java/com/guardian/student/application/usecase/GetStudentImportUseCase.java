package com.guardian.student.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.student.application.port.StudentImportJobRepository;
import com.guardian.student.domain.StudentImportJob;
import com.guardian.student.domain.StudentImportJobId;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reads back a bulk import result (feature STU-002).
 *
 * <p>A plain read — the console polls it to render the summary and the error list. No data-access
 * record is written: the rows it returns describe lines that <em>failed</em> to enrol, not children
 * on the roll, and the operator is looking at the outcome of their own upload. The file download,
 * where child data actually leaves the platform, is audited separately ({@link
 * ExportStudentImportErrorsUseCase}).
 */
@Service
public class GetStudentImportUseCase {

  private final StudentImportJobRepository jobRepository;

  public GetStudentImportUseCase(StudentImportJobRepository jobRepository) {
    this.jobRepository = jobRepository;
  }

  @Transactional(readOnly = true)
  public StudentImportJob byId(StudentImportJobId id) {
    return jobRepository
        .findById(id)
        .orElseThrow(
            () ->
                new ResourceNotFoundException(
                    ErrorCode.STUDENT_IMPORT_NOT_FOUND, "StudentImportJob", id.value()));
  }
}
