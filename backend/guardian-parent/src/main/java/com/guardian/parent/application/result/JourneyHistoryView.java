package com.guardian.parent.application.result;

import com.guardian.parent.domain.JourneyHistoryEntry;
import com.guardian.parent.domain.SchoolClock;
import java.time.Instant;
import java.util.List;
import java.util.Objects;

/**
 * One page of a child's journey history, with the clock its times belong to.
 *
 * <p>The clock travels with the entries rather than being fetched separately, for the same reason
 * it does on the dashboard: every {@code eventAt} below is UTC, and a client that rendered them in
 * the device's zone would show a parent abroad the wrong times for their own child's day
 * (BR-CFG-006).
 */
public record JourneyHistoryView(
    List<JourneyHistoryEntry> entries, SchoolClock clock, Instant observedAt) {

  public JourneyHistoryView {
    Objects.requireNonNull(entries, "entries");
    Objects.requireNonNull(observedAt, "observedAt");
    entries = List.copyOf(entries);
  }
}
