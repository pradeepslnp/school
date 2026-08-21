package com.guardian.parent.application.result;

import com.guardian.parent.domain.ChildJourney;
import com.guardian.parent.domain.JourneyLeg;
import com.guardian.parent.domain.SchoolClock;
import java.time.Instant;
import java.util.List;
import java.util.Objects;

/**
 * One child's full picture (P-03): the same current state the dashboard shows, plus the day's legs.
 *
 * <p>A superset rather than a different shape, so a parent who taps through gets more than they
 * already saw on P-02 instead of a rearrangement of it.
 */
public record ChildDetailView(
    ChildJourney journey, List<JourneyLeg> legs, SchoolClock clock, Instant observedAt) {

  public ChildDetailView {
    Objects.requireNonNull(journey, "journey");
    Objects.requireNonNull(legs, "legs");
    Objects.requireNonNull(observedAt, "observedAt");
    legs = List.copyOf(legs);
  }
}
