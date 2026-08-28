package com.guardian.identity.application;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Component;

/**
 * The one place an administrative password is judged strong enough to accept (ADR-0012, BR-IAM-013).
 *
 * <p>Length-first, following NIST SP 800-63B: a minimum length and a screen against the passwords
 * everyone already tries, and deliberately <em>no</em> forced composition ("one upper, one symbol")
 * or expiry — both push people toward weaker, predictable choices. Applied server-side by every path
 * that sets a password (create-in-password-mode, accept-invitation, reset), because a rule enforced
 * only in the UI is not enforced (ENGINEERING_PRINCIPLES.md §6).
 *
 * <p>Screening against a full breach corpus (HaveIBeenPwned k-anonymity) is a planned enhancement
 * behind this same class; the bundled list below is the floor, not the ceiling.
 */
@Component
@BusinessRule("BR-IAM-013")
public class PasswordPolicy {

  /** Minimum length. A long passphrase beats an unmemorable seven-character jumble. */
  public static final int MIN_LENGTH = 12;

  /**
   * A small denylist of the passwords credential-stuffing tries first. Lowercased; the check is
   * case-insensitive because {@code Password123!} and {@code password123!} are equally guessable.
   */
  private static final Set<String> COMMON =
      Set.of(
          "password",
          "password1",
          "password123",
          "password1234",
          "passw0rd",
          "qwerty123456",
          "123456789012",
          "1234567890123",
          "administrator",
          "admin123456",
          "welcome12345",
          "letmein12345",
          "iloveyou1234",
          "changeme1234",
          "guardian1234",
          "school123456");

  /**
   * @throws BusinessRuleViolationException {@link ErrorCode#VALIDATION_WEAK_PASSWORD} if the
   *     password is too short or on the common-password list. Thrown, not returned — it rolls back
   *     the surrounding transaction, which for a password-setting flow means nothing was persisted.
   */
  public void validate(String password) {
    if (password == null || password.length() < MIN_LENGTH) {
      throw new BusinessRuleViolationException(
          ErrorCode.PASSWORD_TOO_WEAK,
          "BR-IAM-013",
          Map.of("reason", "too_short", "minLength", MIN_LENGTH));
    }
    if (COMMON.contains(password.toLowerCase(Locale.ROOT))) {
      throw new BusinessRuleViolationException(
          ErrorCode.PASSWORD_TOO_WEAK, "BR-IAM-013", Map.of("reason", "common"));
    }
  }
}
