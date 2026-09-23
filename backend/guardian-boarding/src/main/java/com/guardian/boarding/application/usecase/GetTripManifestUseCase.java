package com.guardian.boarding.application.usecase;

import com.guardian.boarding.application.port.TripManifestReadModel;
import com.guardian.boarding.application.result.ManifestEntry;
import com.guardian.common.BusinessRule;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The children a trip expects (TRP-003, BR-TRIP-003).
 *
 * <p>Refuses an unknown trip rather than returning an empty list: "this trip has no children" and
 * "there is no such trip" are different facts, and a crew shown the first when the second is true
 * would drive a route believing nobody was booked on it.
 */
@Service
public class GetTripManifestUseCase {

  private final TripManifestReadModel manifests;

  public GetTripManifestUseCase(TripManifestReadModel manifests) {
    this.manifests = manifests;
  }

  @Transactional(readOnly = true)
  @BusinessRule("BR-TRIP-003")
  public List<ManifestEntry> execute(UUID tripId) {
    manifests
        .statusOf(tripId)
        .orElseThrow(
            () -> new ResourceNotFoundException(ErrorCode.TRIP_NOT_FOUND, "Trip", tripId));

    return manifests.manifestFor(tripId);
  }
}
