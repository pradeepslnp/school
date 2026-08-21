package com.guardian.identity.application.port;

import com.guardian.identity.domain.PasswordCredential;
import com.guardian.identity.domain.UserId;
import java.util.Optional;

/**
 * Persistence for staff passwords. Tenant-scoped by row-level security like everything else that
 * carries {@code tenant_id}.
 *
 * <p>At most one row exists per user — enforced by {@code uq_user_credentials_password}
 * (V3__identity.sql) — unlike {@link OtpCredentialRepository}, which accumulates one row per code
 * issued. {@link #save} is written to reflect that: it updates an existing row when one is found,
 * and only inserts when none exists yet.
 */
public interface PasswordCredentialRepository {

  Optional<PasswordCredential> findByUserId(UserId userId);

  PasswordCredential save(PasswordCredential credential);
}
