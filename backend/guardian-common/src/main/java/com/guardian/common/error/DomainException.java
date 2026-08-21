package com.guardian.common.error;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/**
 * Base type for failures caused by a business rule.
 *
 * <p>Carries an {@link ErrorCode} and structured context — never a user-facing message. The code
 * maps to a localisation key and the context supplies its variables (BR-CFG-005), so the same
 * failure renders in whatever language the recipient reads.
 *
 * <p>Mapped to the standard error envelope by a single {@code @RestControllerAdvice}. Never caught
 * and rethrown at multiple layers; never swallowed.
 */
public abstract class DomainException extends RuntimeException {

  private final ErrorCode errorCode;
  private final transient Map<String, Object> context;

  protected DomainException(ErrorCode errorCode) {
    this(errorCode, Map.of());
  }

  protected DomainException(ErrorCode errorCode, Map<String, Object> context) {
    // The message is for logs and stack traces only. Clients receive the localised
    // messageKey, never this string.
    super(errorCode.name());
    this.errorCode = Objects.requireNonNull(errorCode, "errorCode");
    this.context = Collections.unmodifiableMap(new LinkedHashMap<>(context));
  }

  public ErrorCode errorCode() {
    return errorCode;
  }

  public Map<String, Object> context() {
    return context;
  }

  /** The business rule this failure enforces, where one applies — {@code "BR-TEN-002"}. */
  public String businessRule() {
    return null;
  }
}
