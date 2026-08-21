package com.guardian.tenancy.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * A school's code, unique within its organization and immutable once operational data exists
 * (BR-TEN-007).
 *
 * <p>Validation lives here so an invalid code cannot exist as an object — the type system carries
 * the invariant rather than every caller re-checking it.
 */
public record SchoolCode(String value) {

  private static final Pattern VALID = Pattern.compile("^[A-Z0-9][A-Z0-9_-]{1,31}$");

  public SchoolCode {
    Objects.requireNonNull(value, "value");
    value = value.trim().toUpperCase(Locale.ROOT);
    if (!VALID.matcher(value).matches()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT, "BR-TEN-007", Map.of("field", "code"));
    }
  }

  public static SchoolCode of(String value) {
    return new SchoolCode(value);
  }

  @Override
  public String toString() {
    return value;
  }
}
