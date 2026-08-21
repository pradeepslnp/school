package com.guardian.identity.application;

import com.guardian.common.error.DomainException;
import com.guardian.common.error.ErrorCode;
import java.util.Map;

/**
 * A sign-in attempt the platform refuses.
 *
 * <p>Carries no context map by default, and callers should think twice before adding one. The
 * standard error envelope renders {@code details} to the client, and a detail such as {@code
 * {"phone": "…"}} on an authentication failure hands an attacker confirmation that the number
 * exists.
 *
 * <p>Which {@link ErrorCode} is used is itself a security decision, made in the use cases:
 *
 * <ul>
 *   <li>{@code AUTH_CREDENTIALS_INVALID} covers an unknown number, an inactive account, and a wrong
 *       code alike. Distinguishing them enumerates registered guardians, and a list of registered
 *       guardian numbers is a list of families at a named school.
 *   <li>{@code AUTH_OTP_EXPIRED} and {@code AUTH_OTP_ALREADY_USED} are reported distinctly. Neither
 *       tells an attacker anything they did not already know — they requested the code themselves —
 *       and the client needs them to clear a dead field and offer a fresh code rather than leaving
 *       a parent retyping digits that can never work.
 * </ul>
 */
public class AuthenticationFailedException extends DomainException {

  public AuthenticationFailedException(ErrorCode errorCode) {
    super(errorCode, Map.of());
  }
}
