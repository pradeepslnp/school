package com.guardian.identity.application.port;

import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.UserId;
import java.util.Optional;

/**
 * Persistence for issued one-time codes. Tenant-scoped by row-level security like everything else
 * that carries {@code tenant_id}.
 */
public interface OtpCredentialRepository {

  /**
   * The most recently issued unconsumed code for this user.
   *
   * <p>Newest wins. A guardian who taps "send a new code" twice has two live codes, and accepting
   * the older one would make the button appear broken — they will be reading the newest SMS.
   */
  Optional<OtpCredential> findLatestUnconsumed(UserId userId);

  /**
   * The most recent code of any kind, consumed or not.
   *
   * <p>Needed because a lock survives the code that caused it: after five wrong attempts the lock
   * lives on the credential row, and a caller that only ever looked at unconsumed rows would let a
   * fresh request bypass it.
   */
  Optional<OtpCredential> findLatest(UserId userId);

  OtpCredential save(OtpCredential credential);
}
