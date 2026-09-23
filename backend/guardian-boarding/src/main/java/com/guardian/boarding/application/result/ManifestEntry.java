package com.guardian.boarding.application.result;

import com.guardian.boarding.domain.ManifestEntryStatus;
import java.time.Instant;
import java.time.LocalTime;
import java.util.UUID;

/**
 * One child on a trip's manifest, as the crew's screen reads it (TRP-003).
 *
 * <p>Ordered by stop sequence, because that is the order the bus meets them and therefore the only
 * order a list is usable in at a kerb.
 *
 * @param studentName the snapshot taken when the manifest was materialised, not a live join. A
 *     manifest must still read correctly after a rename, a transfer, or a withdrawal.
 */
public record ManifestEntry(
    UUID studentId,
    String studentName,
    String className,
    UUID expectedStopId,
    String expectedStopName,
    int stopSequenceNo,
    LocalTime scheduledStopTime,
    ManifestEntryStatus status,
    Instant lastEventAt) {}
