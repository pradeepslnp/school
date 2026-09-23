package com.guardian.trip.application.port;

import java.util.UUID;

/**
 * Persistence for {@code trip_manifests} (MOD-08).
 *
 * <p>The manifest is the list of children a trip expects. It is materialised once, at start, and is
 * immutable thereafter (BR-TRIP-003 🔴) — which is what makes trip-close reconciliation meaningful:
 * a fixed expectation to compare the boarding record against. Late changes are manifest amendments
 * with an actor and a reason, never edits to these rows.
 */
public interface TripManifestRepository {

  /**
   * Materialises the manifest for a trip that is starting.
   *
   * <p>Built from the route's active student assignments for this direction, minus every child with
   * an active absence covering this date and run (BR-ABS-002), with each child's name snapshotted
   * so the manifest still reads correctly after a rename or a withdrawal.
   *
   * @return the number of children written. Zero is a refusable condition, not an error here — the
   *     use case decides what an empty manifest means.
   */
  int materialiseFor(UUID tripId);

  /** How many children the trip expects. Used to refuse a start that would record nothing. */
  int countFor(UUID tripId);
}
