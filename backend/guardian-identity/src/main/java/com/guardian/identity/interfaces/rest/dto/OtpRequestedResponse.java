package com.guardian.identity.interfaces.rest.dto;

/**
 * The {@code 202} body for {@code POST /auth/otp/request}.
 *
 * <p>Identical whether or not the number is registered — that is the entire contract. The wording
 * is conditional ("if this number is registered") because the server genuinely does not say, and a
 * confident "a code has been sent" would be a lie in half the cases and a disclosure in the other
 * half.
 *
 * <p>{@code message} is a fallback string. Clients render from their own resources; this is here
 * for a curl session and a log, never as the authority for display (BR-CFG-005).
 */
public record OtpRequestedResponse(String message, long expiresIn) {

  public static OtpRequestedResponse of(long expiresInSeconds) {
    return new OtpRequestedResponse(
        "If this number is registered, a code has been sent.", expiresInSeconds);
  }
}
