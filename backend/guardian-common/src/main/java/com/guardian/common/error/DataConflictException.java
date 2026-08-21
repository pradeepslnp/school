package com.guardian.common.error;

import java.util.Map;

/**
 * A well-formed request refused by a database-level uniqueness constraint that is not itself a
 * documented business rule — e.g. an employee code already used within a school ({@code
 * uq_staff_school_employee_code}). Distinct from {@link BusinessRuleViolationException}, which
 * requires a {@code businessRule} citation: not every conflict this platform reports traces back to
 * one, and forcing a BR label onto a plain data-integrity constraint would misattribute it. {@link
 * DomainException#businessRule()} stays null here, matching {@link ResourceNotFoundException}'s
 * treatment of the same distinction.
 */
public class DataConflictException extends DomainException {

  public DataConflictException(ErrorCode errorCode, Map<String, Object> context) {
    super(errorCode, context);
  }
}
