package com.guardian.boarding.domain;

/**
 * What happened to a child at a stop (BR-BOARD-002).
 *
 * <p>Two events, not a single "attendance" flag, because the pair is the evidence: a BOARD with no
 * matching ALIGHT is precisely the unaccounted child BR-SAFE-001 exists to catch. A boolean would
 * make that condition unrepresentable.
 */
public enum BoardingEventType {
  BOARD,
  ALIGHT
}
