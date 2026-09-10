package com.guardian.student.application;

import com.guardian.common.error.DomainException;
import com.guardian.common.error.ErrorCode;
import java.util.Map;

/**
 * The uploaded file was refused before any row was processed (feature STU-002).
 *
 * <p>Distinct from a per-row {@link com.guardian.student.domain.ImportRowError}: this is the file
 * being unusable as a whole — empty, not the CSV it claimed to be, carrying a column this version
 * cannot process, or larger than one synchronous request should handle. Nothing is enrolled and no
 * import job is recorded, so the office fixes the file and uploads again.
 *
 * <p>Concrete rather than reusing {@link com.guardian.common.error.BusinessRuleViolationException}:
 * none of these conditions trace to a documented business rule, and forcing a {@code BR-} citation
 * onto them would misattribute the failure — the same reasoning {@link
 * com.guardian.common.error.DataConflictException} follows.
 */
public class StudentImportRejectedException extends DomainException {

  public StudentImportRejectedException(ErrorCode errorCode) {
    super(errorCode);
  }

  public StudentImportRejectedException(ErrorCode errorCode, Map<String, Object> context) {
    super(errorCode, context);
  }
}
