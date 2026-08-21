package com.guardian.notification.interfaces.rest.dto;

import com.guardian.notification.domain.NotificationEntry;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * One entry as the parent app reads it.
 *
 * <p>{@code title} is the fallback copy, sent so a client with no localisation bundle still has
 * something complete to render on a lock screen. {@code bodyKey} and {@code bodyParams} travel
 * alongside it so a localised client renders properly rather than displaying the server's language
 * (BR-CFG-005) — the client prefers the key and falls back to the title, never the reverse.
 */
public record NotificationResponse(
    UUID id,
    String catalogId,
    String priority,
    String title,
    String bodyKey,
    Map<String, Object> bodyParams,
    UUID studentId,
    String studentDisplayName,
    UUID tripId,
    Instant occurredAt,
    boolean isRead) {

  public static NotificationResponse from(NotificationEntry entry) {
    return new NotificationResponse(
        entry.id(),
        entry.catalogId(),
        entry.priority().name(),
        entry.bodyFallback(),
        entry.bodyKey(),
        entry.bodyParams(),
        entry.studentId(),
        entry.studentDisplayName(),
        entry.tripId(),
        entry.occurredAt(),
        entry.isRead());
  }
}
