package com.guardian.boarding.interfaces.rest.dto;

import com.guardian.boarding.application.result.ManifestEntry;
import java.time.Instant;
import java.time.LocalTime;
import java.util.UUID;

/** One child on a trip's manifest, as the crew's screen reads it. */
public record ManifestEntryResponse(
    UUID studentId,
    String studentName,
    String className,
    UUID expectedStopId,
    String expectedStopName,
    int stopSequenceNo,
    LocalTime scheduledStopTime,
    String status,
    Instant lastEventAt) {

  public static ManifestEntryResponse from(ManifestEntry entry) {
    return new ManifestEntryResponse(
        entry.studentId(),
        entry.studentName(),
        entry.className(),
        entry.expectedStopId(),
        entry.expectedStopName(),
        entry.stopSequenceNo(),
        entry.scheduledStopTime(),
        entry.status().name(),
        entry.lastEventAt());
  }
}
