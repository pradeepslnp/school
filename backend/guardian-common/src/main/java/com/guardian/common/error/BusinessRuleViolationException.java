package com.guardian.common.error;

import java.util.Map;
import java.util.Objects;

/**
 * A well-formed request refused by a business rule.
 *
 * <p>Surfaces as HTTP 422 with the {@code businessRule} field populated. That field is deliberate:
 * a driver refused at 06:30 needs to know <em>which</em> check failed, and a support engineer needs
 * to find the rule without reading source (guardian-docs/04-api/API_STANDARDS.md).
 */
public class BusinessRuleViolationException extends DomainException {

  private final String businessRule;

  public BusinessRuleViolationException(
      ErrorCode errorCode, String businessRule, Map<String, Object> context) {
    super(errorCode, context);
    this.businessRule = Objects.requireNonNull(businessRule, "businessRule");
  }

  public BusinessRuleViolationException(ErrorCode errorCode, String businessRule) {
    this(errorCode, businessRule, Map.of());
  }

  @Override
  public String businessRule() {
    return businessRule;
  }
}
