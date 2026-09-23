package com.guardian.boarding.application.port;

import com.guardian.boarding.application.result.ManifestEntry;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Reads a trip's manifest and the few trip facts MOD-09 has to check before writing. */
public interface TripManifestReadModel {

  List<ManifestEntry> manifestFor(UUID tripId);

  /**
   * The trip's status, for the "is this run accepting events" check.
   *
   * <p>A status string rather than MOD-08's enum: MOD-09 must not depend on MOD-08's Java to ask
   * one question about one column, and the two modules sit side by side in the map rather than one
   * above the other.
   */
  Optional<String> statusOf(UUID tripId);
}
