package com.guardian.boarding.application.port;

import com.guardian.boarding.domain.BoardingEvent;
import com.guardian.boarding.domain.BoardingEventType;
import com.guardian.boarding.domain.ManifestEntryStatus;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for {@code boarding_events} and the manifest projection it drives (MOD-09).
 *
 * <p>Append-only: there is no update and no delete here, and that absence is the design. A
 * repository that offered one would be a repository a future code path could use (BR-BOARD-001 🔴).
 * The single {@code updateManifestStatus} is not an exception — it maintains a projection derived
 * from the events, not the events themselves.
 */
public interface BoardingEventRepository {

  /**
   * The event already recorded under this idempotency key, if any (BR-BOARD-009).
   *
   * <p>Looked up before anything is validated, so a retry of a request that already succeeded
   * returns the original record instead of being refused by a rule the first attempt already
   * passed — a queued offline event retried after the child has since alighted must not fail with
   * "already boarded".
   */
  Optional<BoardingEvent> findByClientEventId(UUID clientEventId);

  BoardingEvent append(BoardingEvent event);

  /**
   * Appends an event that contradicts server state, marked {@code FLAGGED_FOR_REVIEW}
   * (BR-SAFE-005 🔴).
   *
   * <p>Separate from {@link #append} so that writing a questionable record is a deliberate call a
   * reader can find, not a boolean on the ordinary path that is easy to pass by accident.
   */
  BoardingEvent appendFlagged(BoardingEvent event);

  /** The child's most recent event on this trip, which decides what may happen next. */
  Optional<BoardingEventType> lastEventTypeFor(UUID tripId, UUID studentId);

  /** Whether this child is on this trip's manifest at all (BR-BOARD-003). */
  boolean isOnManifest(UUID tripId, UUID studentId);

  /** The stop the manifest expects this child at, for the wrong-stop check (BR-BOARD-004). */
  Optional<UUID> expectedStopFor(UUID tripId, UUID studentId);

  /**
   * Another trip today, in the same direction, whose manifest does expect this child (BR-SAFE-003).
   *
   * <p>The wrong-vehicle detection. Present means the child is being boarded onto a bus that is
   * not theirs while their own is running — the most serious thing this module can notice.
   */
  Optional<UUID> otherTripExpectingStudent(UUID tripId, UUID studentId);

  void updateManifestStatus(UUID tripId, UUID studentId, ManifestEntryStatus status);
}
