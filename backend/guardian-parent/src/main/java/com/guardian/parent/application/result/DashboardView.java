package com.guardian.parent.application.result;

import com.guardian.parent.domain.ChildJourney;
import com.guardian.parent.domain.SchoolClock;
import java.time.Instant;
import java.util.List;
import java.util.Objects;

/**
 * One reading of the parent dashboard: every child the caller may see, and the clock they are
 * described in.
 *
 * <p>{@code observedAt} travels with the children rather than being taken from the client's own
 * clock on arrival. That is what lets the app say "last updated 07:44" honestly while offline — the
 * time belongs to the data, not to the moment it was rendered.
 *
 * @param clock the school's zone, null only when the guardian has no children linked and there is
 *     therefore no school to report
 */
public record DashboardView(List<ChildJourney> children, SchoolClock clock, Instant observedAt) {

  public DashboardView {
    Objects.requireNonNull(children, "children");
    Objects.requireNonNull(observedAt, "observedAt");
    children = List.copyOf(children);
  }
}
