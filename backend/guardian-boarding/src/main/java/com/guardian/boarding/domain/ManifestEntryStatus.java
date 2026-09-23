package com.guardian.boarding.domain;

/**
 * Where one child on a trip's manifest currently stands.
 *
 * <p>Derived from the boarding events and kept on the manifest row as a projection, never as the
 * source of truth: the events are the evidence, and the status exists so the crew's screen does
 * not have to re-derive it for forty children on every refresh.
 */
public enum ManifestEntryStatus {
  /** On the list, nothing recorded yet. */
  EXPECTED,
  /** Boarded, still aboard. */
  BOARDED,
  /** Boarded and got off. The only complete state. */
  ALIGHTED,
  /** The vehicle passed their stop with no board event (BR-SAFE-002). */
  NO_SHOW,
  /** A guardian declared them not travelling (BR-ABS-001). */
  ABSENT
}
