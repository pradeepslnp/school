package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantContext;
import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.Session;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** Implements {@link SessionRepository} over JPA. */
@Component
class SessionRepositoryAdapter implements SessionRepository {

  private final SessionJpaRepository jpaRepository;

  SessionRepositoryAdapter(SessionJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Optional<Session> findById(SessionId id) {
    return jpaRepository.findById(id.value()).map(SessionRepositoryAdapter::toDomain);
  }

  @Override
  public List<Session> findByUser(UserId userId) {
    return jpaRepository.findByUserIdOrderByIssuedAtDesc(userId.value()).stream()
        .map(SessionRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  public Session save(Session session) {
    Optional<SessionEntity> managed = jpaRepository.findById(session.id().value());

    if (managed.isPresent()) {
      SessionEntity entity = managed.get();
      entity.applyLifecycle(session.consumedAt(), session.isRevoked(), session.revokedReason());
      return toDomain(jpaRepository.save(entity));
    }

    SessionEntity entity =
        new SessionEntity(
            session.id().value(),
            TenantContext.require().value(),
            session.userId().value(),
            session.refreshTokenHash(),
            session.familyId(),
            session.previousSessionId() == null ? null : session.previousSessionId().value(),
            session.clientType().name(),
            session.deviceIdentifier(),
            session.issuedAt(),
            session.expiresAt(),
            session.consumedAt(),
            session.isRevoked(),
            session.revokedReason());

    return toDomain(jpaRepository.save(entity));
  }

  @Override
  public int revokeFamily(UUID familyId, String reason, Instant now) {
    // `now` is part of the port's shape but unused here: revocation sets no timestamp of its
    // own. Marking the revoked rows consumed would make them report as reuse on next
    // presentation, turning one theft into a permanent false alarm for every session in the
    // family. See Session.revoke.
    return jpaRepository.revokeFamily(familyId, reason);
  }

  @Override
  public int revokeAllForUser(UUID userId, String reason) {
    return jpaRepository.revokeAllForUser(userId, reason);
  }

  private static Session toDomain(SessionEntity entity) {
    return Session.rehydrate(
        SessionId.of(entity.getId()),
        UserId.of(entity.getUserId()),
        entity.getRefreshTokenHash(),
        entity.getFamilyId(),
        entity.getPreviousSessionId() == null ? null : SessionId.of(entity.getPreviousSessionId()),
        ClientType.fromWire(entity.getClientType()),
        entity.getDeviceIdentifier(),
        entity.getIssuedAt(),
        entity.getExpiresAt(),
        entity.getConsumedAt(),
        entity.isRevoked(),
        entity.getRevokedReason(),
        entity.getVersion());
  }
}
