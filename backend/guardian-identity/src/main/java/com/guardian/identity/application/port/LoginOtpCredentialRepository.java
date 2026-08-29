package com.guardian.identity.application.port;

import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.UserId;
import java.util.Optional;

/**
 * Persistence for the emailed sign-in one-time code (IAM-001, ADR-0012).
 *
 * <p>A third repository over the same {@link OtpCredential} shape, kept separate from {@link
 * OtpCredentialRepository} (phone sign-in) and {@link ResetOtpCredentialRepository} (password
 * reset) because the three live under different {@code credential_type} values on purpose — see
 * V17's own comment on why credential confusion is the failure being designed out.
 */
public interface LoginOtpCredentialRepository {

  /** The most recent sign-in code issued to the user (used or not), for verification and lockout. */
  Optional<OtpCredential> findLatest(UserId userId);

  OtpCredential save(OtpCredential credential);
}
