package com.guardian.notification.application.usecase;

import com.guardian.notification.application.port.NotificationRepository;
import com.guardian.notification.domain.NotificationEntry;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The notification centre — feature NTF-006, screen P-08.
 *
 * <p>Read and acknowledge are one use case because they are one screen's behaviour, and both are
 * the same single rule: a user touches only their own notifications. Splitting them into two
 * classes would duplicate that rule rather than clarify anything.
 */
@Service
public class NotificationCentreUseCase {

  /**
   * Enough to scroll back through a term of routine traffic without paging.
   *
   * <p>Capped rather than open-ended for the same reason journey history is: this list grows for as
   * long as a child is enrolled, and an unbounded default is a slow query waiting for a
   * long-standing account.
   */
  private static final int DEFAULT_LIMIT = 200;

  private final NotificationRepository notifications;

  public NotificationCentreUseCase(NotificationRepository notifications) {
    this.notifications = notifications;
  }

  /**
   * The caller's notification centre, with the clock its timestamps belong to.
   *
   * <p>Returned together rather than as two calls: a client that fetched entries and zone
   * separately could render one against the other's staleness, and the zone is a property of the
   * response, not of the session.
   */
  @Transactional(readOnly = true)
  public NotificationCentre forUser(UUID userId) {
    return new NotificationCentre(
        notifications.findForUser(userId, DEFAULT_LIMIT),
        notifications.schoolTimezoneFor(userId).orElse(null));
  }

  /**
   * @param schoolTimezoneId IANA zone, or null when the user is linked to no school. Null means the
   *     response omits {@code meta.school} rather than substituting UTC — an unlabelled fallback is
   *     what BR-CFG-006 exists to prevent.
   */
  public record NotificationCentre(List<NotificationEntry> entries, String schoolTimezoneId) {}

  /**
   * Acknowledges an entry.
   *
   * <p>Idempotent, and silent about an id that is not the caller's. Marking an already-read entry
   * read again is not an error, and reporting "not found" for someone else's id would confirm the
   * id exists — so both non-updates return quietly.
   */
  @Transactional
  public void markRead(UUID userId, UUID notificationId) {
    notifications.markRead(userId, notificationId);
  }
}
