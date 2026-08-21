package com.guardian.student.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * A student's admission number — the identifier the school already uses for them (BR-STU-003).
 *
 * <p>Normalised to upper case before validation, because "gw-2024-0117" and "GW-2024-0117" are the
 * same child to the office. Without normalisation the uniqueness constraint would admit both and
 * the register would show a duplicate that staff cannot tell apart.
 *
 * <p>Uniqueness itself is a cross-row rule and lives in the use case; this type only guarantees the
 * value is well-formed.
 */
public record AdmissionNumber(String value) {

  /**
   * Deliberately permissive. Schools arrive with existing numbering — "2024/117", "GW-2024-0117",
   * "117" — and a format this platform invents would reject the data the school actually holds.
   * What is refused is only what cannot identify anybody: blank, or too long for the column.
   */
  private static final Pattern VALID = Pattern.compile("^[A-Z0-9][A-Z0-9 ._/-]{0,63}$");

  public AdmissionNumber {
    Objects.requireNonNull(value, "value");
    value = value.trim().toUpperCase(Locale.ROOT);
    if (!VALID.matcher(value).matches()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT, "BR-STU-003", Map.of("field", "admissionNo"));
    }
  }

  public static AdmissionNumber of(String value) {
    return new AdmissionNumber(value);
  }

  @Override
  public String toString() {
    return value;
  }
}
