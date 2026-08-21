package com.guardian.fleet.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

/**
 * A vehicle's registration (licence plate) number.
 *
 * <p>Unique within its organization (BR-FLEET-001). Normalised to upper case with surrounding
 * whitespace trimmed so "dl1pc1234" and "DL1PC1234" are recognised as the same vehicle rather than
 * colliding only at the database's discretion.
 *
 * <p>Deliberately not format-validated against a country pattern: plate formats vary by region
 * (ADR-0007) and a code-level regex here would repeat the mistake that ADR forbids for document and
 * credential types.
 */
public record RegistrationNo(String value) {

  private static final int MAX_LENGTH = 32;

  public RegistrationNo {
    Objects.requireNonNull(value, "value");
    value = value.trim().toUpperCase(Locale.ROOT);
    if (value.isEmpty() || value.length() > MAX_LENGTH) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT, "BR-FLEET-001", Map.of("field", "registrationNo"));
    }
  }

  public static RegistrationNo of(String value) {
    return new RegistrationNo(value);
  }

  @Override
  public String toString() {
    return value;
  }
}
