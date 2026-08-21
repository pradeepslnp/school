package com.guardian.notification.application.port;

import com.guardian.notification.domain.NotificationEntry;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for the notification centre.
 *
 * <p>Both methods take the recipient's user id and filter on it in SQL. There is no "find by id"
 * that a caller could use without knowing whose notification it is — the id alone must never be
 * enough to read or acknowledge someone else's entry.
 */
public interface NotificationRepository {

  /** The caller's own notifications, newest first, capped at {@code limit}. */
  List<NotificationEntry> findForUser(UUID userId, int limit);

  /**
   * Marks one entry read, but only if it belongs to {@code userId}.
   *
   * @return true when a row was updated; false when the id is unknown <em>or</em> belongs to
   *     someone else. The caller treats both the same way, so a guessed id reveals nothing.
   */
  boolean markRead(UUID userId, UUID notificationId);

  /**
   * The IANA zone of the school this user's notifications concern, or empty when they have none.
   *
   * <p>Every {@code occurredAt} is UTC, and the client renders in the school's zone (BR-CFG-006).
   * Without this the notification centre would fall back to the device's zone and show a parent
   * abroad the wrong times for their own child's day — which is not incomplete information, it is
   * false information.
   */
  Optional<String> schoolTimezoneFor(UUID userId);
}
