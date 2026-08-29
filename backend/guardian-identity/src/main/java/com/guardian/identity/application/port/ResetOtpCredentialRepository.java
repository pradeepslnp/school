package com.guardian.identity.application.port;

import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.UserId;
import java.util.Optional;

/**
 * Persistence for the emailed password-reset one-time code (ADR-0012).
 *
 * <p>Distinct from {@link OtpCredentialRepository} even though both store an {@link OtpCredential}:
 * the two are kept in different {@code credential_type} rows ({@code OTP} for phone sign-in, {@code
 * RESET} here) precisely so a sign-in code can never be replayed as a reset, nor a reset code used
 * to sign in. Same tenant-scoped, single-use, attempt-locked machinery; different purpose.
 */
public interface ResetOtpCredentialRepository {

  /** The most recent reset code issued to the user (used or not), for verification and lockout. */
  Optional<OtpCredential> findLatest(UserId userId);

  OtpCredential save(OtpCredential credential);
}
