package com.guardian.fleet.application.port;

import com.guardian.fleet.domain.VehicleDocument;
import com.guardian.fleet.domain.VehicleDocumentId;
import com.guardian.fleet.domain.VehicleId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface VehicleDocumentRepository {

  Optional<VehicleDocument> findById(VehicleDocumentId id);

  List<VehicleDocument> findByVehicle(VehicleId vehicleId);

  /** Mandatory documents only — the set BR-FLEET-002 checks at trip start. */
  List<VehicleDocument> findMandatoryByVehicle(VehicleId vehicleId);

  /**
   * Mandatory documents expiring within {@code days} of {@code asOf}, bounded per
   * CODING_STANDARDS_BACKEND.md — every history or list query is bounded, never a full scan.
   */
  List<VehicleDocument> findMandatoryExpiringWithin(LocalDate asOf, int days, int limit);

  VehicleDocument save(VehicleDocument document);
}
