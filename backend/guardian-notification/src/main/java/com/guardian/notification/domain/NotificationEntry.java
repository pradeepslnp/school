package com.guardian.notification.domain;

import java.time.Instant;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * One entry in the notification centre (NTF-006, screen P-08).
 *
 * <p>The durable record, not the delivery. A push that was never opened, an SMS that arrived while
 * the phone was off — both leave a row here, because "a parent who missed a push must be able to
 * scroll back and find it" (guardian-docs/05-ui/PARENT_APP.md).
 *
 * @param catalogId the {@code NTF-AREA-nn} entry this came from
 *     (guardian-docs/01-product-discovery/NOTIFICATION_CATALOG.md). Kept so "which message is this"
 *     is answerable without parsing prose.
 * @param bodyKey a localisation key, with {@code bodyParams} supplying its variables. The server
 *     does not know the recipient's language, so it stores the key and the client renders
 *     (BR-CFG-005). A rendered string would be frozen in whatever locale the dispatcher ran in.
 * @param bodyFallback copy in the tenant's default locale, for a client with no bundle for {@code
 *     bodyKey} yet. Never the authority for display.
 */
public record NotificationEntry(
    UUID id,
    String catalogId,
    Priority priority,
    String bodyKey,
    Map<String, Object> bodyParams,
    String bodyFallback,
    UUID studentId,
    /* Which child this concerns, for the entry's subtitle. Never another family's
     * (BR-NTF-007 🔴) — the query resolves it only through the recipient's own guardian link. */
    String studentDisplayName,
    UUID tripId,
    Instant occurredAt,
    Instant readAt) {

  public NotificationEntry {
    Objects.requireNonNull(id, "id");
    Objects.requireNonNull(catalogId, "catalogId");
    Objects.requireNonNull(priority, "priority");
    Objects.requireNonNull(occurredAt, "occurredAt");
    bodyParams = bodyParams == null ? Map.of() : Map.copyOf(bodyParams);
  }

  public boolean isRead() {
    return readAt != null;
  }

  /**
   * The four priority classes from the catalog.
   *
   * <p>Only {@link #CRITICAL} is exempt from preferences and quiet hours (BR-NTF-006 🔴) — and that
   * exemption is what makes the rest safe to mute. A parent can silence routine traffic precisely
   * because the events that matter always arrive.
   *
   * <p>On this screen the class drives emphasis only; the exemption is a dispatch concern.
   */
  public enum Priority {
    CRITICAL,
    URGENT,
    STANDARD,
    INFO
  }
}
