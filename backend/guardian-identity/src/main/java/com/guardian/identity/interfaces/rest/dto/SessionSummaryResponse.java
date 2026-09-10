package com.guardian.identity.interfaces.rest.dto;

import com.guardian.identity.application.result.SessionSummary;
import java.time.Instant;

/**
 * Wire representation of one signed-in session, matching guardian-docs/04-api/AUTHENTICATION_API.md
 * § {@code GET /auth/sessions}.
 *
 * <p>No token material — see {@link SessionSummary}.
 */
public record SessionSummaryResponse(
    String id,
    String clientType,
    String deviceIdentifier,
    Instant issuedAt,
    Instant expiresAt,
    String status,
    boolean isCurrent) {

  public static SessionSummaryResponse from(SessionSummary summary) {
    return new SessionSummaryResponse(
        summary.id(),
        summary.clientType(),
        summary.deviceIdentifier(),
        summary.issuedAt(),
        summary.expiresAt(),
        summary.status(),
        summary.current());
  }
}
