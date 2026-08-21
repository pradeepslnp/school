package com.guardian.parent.domain;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Objects;

/**
 * The school's timezone, carried alongside every response that contains a time.
 *
 * <p>All timestamps go out as UTC and the client renders in the school's zone (BR-CFG-006,
 * guardian-docs/04-api/API_STANDARDS.md). The offset travels with the data rather than being looked
 * up on the device, so a parent abroad and a parent at the school gate convert identically — the
 * device's own zone is never consulted, because "07:42" shown in the wrong zone is not incomplete
 * information, it is false information.
 *
 * <p>{@code utcOffsetMinutes} is resolved for a given instant rather than fixed, so a school in a
 * zone that observes daylight saving reports the offset actually in force today.
 */
public record SchoolClock(ZoneId zoneId) {

  public SchoolClock {
    Objects.requireNonNull(zoneId, "zoneId");
  }

  public static SchoolClock of(String zoneId) {
    return new SchoolClock(ZoneId.of(zoneId));
  }

  public String timezoneId() {
    return zoneId.getId();
  }

  /** The school's offset from UTC at {@code at}, in minutes — what {@code meta.school} carries. */
  public int utcOffsetMinutesAt(Instant at) {
    ZoneOffset offset = zoneId.getRules().getOffset(at);
    return offset.getTotalSeconds() / 60;
  }
}
