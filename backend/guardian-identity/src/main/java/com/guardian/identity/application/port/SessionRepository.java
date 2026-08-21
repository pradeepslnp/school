package com.guardian.identity.application.port;

import com.guardian.identity.domain.Session;
import com.guardian.identity.domain.SessionId;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Persistence for issued sessions. */
public interface SessionRepository {

  Optional<Session> findById(SessionId id);

  Session save(Session session);

  /**
   * Revokes every session in a rotation family and returns how many were affected.
   *
   * <p>Expressed as one repository operation rather than a load-modify-save loop in the use case,
   * because it must be atomic: a partial family revocation leaves exactly the sessions an attacker
   * is using. The count is returned so the security event can record the blast radius.
   *
   * @see com.guardian.identity.domain.Session for why the whole family goes (BR-IAM-009)
   */
  int revokeFamily(UUID familyId, String reason, Instant now);
}
