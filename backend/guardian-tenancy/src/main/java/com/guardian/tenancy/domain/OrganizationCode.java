package com.guardian.tenancy.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * An organization's code, unique across the platform and immutable once operational data exists
 * (BR-TEN-007).
 *
 * <p>Unlike {@link SchoolCode}, whose scope is one organization, this code's parent scope is the
 * platform itself — enforced by {@code uq_organizations_code} rather than a composite key.
 */
public record OrganizationCode(String value) {

  private static final Pattern VALID = Pattern.compile("^[A-Z0-9][A-Z0-9_-]{1,31}$");

  public OrganizationCode {
    Objects.requireNonNull(value, "value");
    value = value.trim().toUpperCase(Locale.ROOT);
    if (!VALID.matcher(value).matches()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT, "BR-TEN-007", Map.of("field", "code"));
    }
  }

  public static OrganizationCode of(String value) {
    return new OrganizationCode(value);
  }

  @Override
  public String toString() {
    return value;
  }
}
