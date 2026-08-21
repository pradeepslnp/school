package com.guardian.parent.interfaces.rest.dto;

import com.guardian.parent.domain.SchoolClock;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * The {@code meta} block for a parent response.
 *
 * <p>Exists because {@code meta.school} is <strong>required</strong> on this endpoint
 * (guardian-docs/04-api/STUDENTS_GUARDIANS_API.md). Every timestamp in the payload is UTC, and the
 * client renders in the school's zone; without this block it would have nothing to render with and
 * would fall back to the device's zone — which is exactly the travelling-parent bug BR-CFG-006
 * exists to prevent.
 *
 * <p>The offset is resolved <em>for the response instant</em> rather than stored, so a school in a
 * zone observing daylight saving reports the offset actually in force today.
 *
 * <p>The controller builds the whole envelope itself, so {@code ResponseEnvelopeAdvice} leaves it
 * alone — it skips any body already carrying a {@code data} key. That is deliberate: the advice's
 * generic {@code meta} has no way to know about a school.
 */
public final class ResponseMeta {

  private ResponseMeta() {}

  public static Map<String, Object> of(SchoolClock clock, Instant observedAt) {
    Map<String, Object> meta = new LinkedHashMap<>();
    meta.put("timestamp", observedAt.toString());

    if (clock != null) {
      Map<String, Object> school = new LinkedHashMap<>();
      school.put("timezoneId", clock.timezoneId());
      school.put("utcOffsetMinutes", clock.utcOffsetMinutesAt(observedAt));
      meta.put("school", school);
    }
    return meta;
  }
}
