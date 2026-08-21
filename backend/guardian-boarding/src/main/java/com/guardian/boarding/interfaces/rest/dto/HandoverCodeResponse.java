package com.guardian.boarding.interfaces.rest.dto;

import com.guardian.boarding.domain.HandoverCode;
import java.time.Instant;
import java.util.UUID;

/**
 * Wire form of an issued handover code.
 *
 * <p>Carries {@code expiresAt} rather than a pre-computed "seconds remaining": the client already
 * renders every other freshness/expiry indicator in the app from a timestamp plus its own clock
 * (docs/05-ui/PARENT_APP.md, freshness indicators), and a server-computed countdown would be stale
 * the moment the response left the wire.
 */
public record HandoverCodeResponse(UUID id, UUID studentId, String code, Instant expiresAt) {

  public static HandoverCodeResponse from(HandoverCode code) {
    return new HandoverCodeResponse(code.id(), code.studentId(), code.code(), code.expiresAt());
  }
}
