package com.guardian.notification.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.notification.application.usecase.NotificationCentreUseCase;
import com.guardian.notification.interfaces.rest.dto.NotificationResponse;
import java.time.Instant;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The notification centre — feature NTF-006, screen P-08. See
 * guardian-docs/04-api/TRACKING_NOTIFICATION_API.md § Notifications.
 *
 * <p>Both endpoints act on the caller's own notifications only, and {@code /me} takes no identifier
 * at all — an endpoint that accepted a user id would be an endpoint that could be asked about
 * somebody else's messages, which for this platform means somebody else's child (BR-NTF-007 🔴).
 */
@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

  private final NotificationCentreUseCase notificationCentre;

  public NotificationController(NotificationCentreUseCase notificationCentre) {
    this.notificationCentre = notificationCentre;
  }

  /**
   * The notification centre.
   *
   * <p>Builds its own envelope so {@code meta.school} can be included: every {@code occurredAt} is
   * UTC and the client renders in the school's zone (BR-CFG-006). {@code ResponseEnvelopeAdvice}
   * leaves a body that already carries {@code data} alone.
   */
  @GetMapping("/me")
  @RequiresPermission("PERM-NOTIFICATION-SELF-VIEW")
  public Map<String, Object> mine(CurrentActor actor) {
    NotificationCentreUseCase.NotificationCentre centre =
        notificationCentre.forUser(actor.userId());

    List<NotificationResponse> data =
        centre.entries().stream().map(NotificationResponse::from).toList();

    Instant now = Instant.now();
    Map<String, Object> meta = new LinkedHashMap<>();
    meta.put("timestamp", now.toString());
    if (centre.schoolTimezoneId() != null) {
      ZoneId zone = ZoneId.of(centre.schoolTimezoneId());
      Map<String, Object> school = new LinkedHashMap<>();
      school.put("timezoneId", zone.getId());
      // Resolved for this instant, so a school observing daylight saving reports the offset
      // actually in force today rather than a stored one.
      school.put("utcOffsetMinutes", zone.getRules().getOffset(now).getTotalSeconds() / 60);
      meta.put("school", school);
    }

    Map<String, Object> body = new LinkedHashMap<>();
    body.put("data", data);
    body.put("meta", meta);
    return body;
  }

  /**
   * Acknowledges one entry.
   *
   * <p>{@code 204} whether or not a row changed. Already read, unknown id, someone else's id — all
   * the same answer, because a distinguishable response would let a caller probe for which
   * notification ids exist.
   */
  @PostMapping("/{notificationId}/read")
  @RequiresPermission("PERM-NOTIFICATION-SELF-VIEW")
  public ResponseEntity<Void> markRead(@PathVariable UUID notificationId, CurrentActor actor) {
    notificationCentre.markRead(actor.userId(), notificationId);
    return ResponseEntity.noContent().build();
  }
}
