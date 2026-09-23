package com.guardian.trip.domain;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * The transition table is the whole rule (BR-TRIP-002), so it is tested directly rather than
 * through the use cases that consult it. A wrong edge here is a trip that can be started twice or
 * closed without ever running.
 */
class TripStatusTest {

  @Test
  @DisplayName("a scheduled trip may start or be cancelled, and nothing else")
  void scheduledTransitions() {
    assertThat(TripStatus.SCHEDULED.canTransitionTo(TripStatus.IN_PROGRESS)).isTrue();
    assertThat(TripStatus.SCHEDULED.canTransitionTo(TripStatus.CANCELLED)).isTrue();
    assertThat(TripStatus.SCHEDULED.canTransitionTo(TripStatus.COMPLETED)).isFalse();
    assertThat(TripStatus.SCHEDULED.canTransitionTo(TripStatus.CLOSED)).isFalse();
  }

  @Test
  @DisplayName("a running trip may complete or be cancelled, but may not go back to scheduled")
  void inProgressTransitions() {
    assertThat(TripStatus.IN_PROGRESS.canTransitionTo(TripStatus.COMPLETED)).isTrue();
    assertThat(TripStatus.IN_PROGRESS.canTransitionTo(TripStatus.CANCELLED)).isTrue();
    assertThat(TripStatus.IN_PROGRESS.canTransitionTo(TripStatus.SCHEDULED)).isFalse();
    assertThat(TripStatus.IN_PROGRESS.canTransitionTo(TripStatus.CLOSED)).isFalse();
  }

  @Test
  @DisplayName("closing is only reachable from completed — reconciliation happens in between")
  void closingRequiresCompletion() {
    assertThat(TripStatus.COMPLETED.canTransitionTo(TripStatus.CLOSED)).isTrue();
    assertThat(TripStatus.COMPLETED.canTransitionTo(TripStatus.CANCELLED)).isFalse();
  }

  @Test
  @DisplayName("terminal statuses go nowhere, including to themselves")
  void terminalStatusesAreFinal() {
    for (TripStatus target : TripStatus.values()) {
      assertThat(TripStatus.CLOSED.canTransitionTo(target)).isFalse();
      assertThat(TripStatus.CANCELLED.canTransitionTo(target)).isFalse();
    }
    assertThat(TripStatus.CLOSED.isTerminal()).isTrue();
    assertThat(TripStatus.CANCELLED.isTerminal()).isTrue();
    assertThat(TripStatus.IN_PROGRESS.isTerminal()).isFalse();
  }

  @Test
  @DisplayName("no status may transition to itself — a repeat request is refused, not absorbed")
  void noSelfTransition() {
    for (TripStatus status : TripStatus.values()) {
      assertThat(status.canTransitionTo(status)).isFalse();
    }
  }

  @Test
  @DisplayName("allowedNext explains a refusal without duplicating the table")
  void allowedNextMatchesTheTable() {
    assertThat(TripStatus.SCHEDULED.allowedNext())
        .containsExactlyInAnyOrder(TripStatus.IN_PROGRESS, TripStatus.CANCELLED);
    assertThat(TripStatus.CLOSED.allowedNext()).isEmpty();
  }
}
