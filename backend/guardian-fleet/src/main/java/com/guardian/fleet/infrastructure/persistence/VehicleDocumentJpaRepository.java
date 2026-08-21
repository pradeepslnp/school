package com.guardian.fleet.infrastructure.persistence;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Package-private — callers use {@link
 * com.guardian.fleet.application.port.VehicleDocumentRepository} via {@link
 * VehicleDocumentRepositoryAdapter}.
 */
interface VehicleDocumentJpaRepository extends JpaRepository<VehicleDocumentEntity, UUID> {

  List<VehicleDocumentEntity> findByVehicleId(UUID vehicleId);

  List<VehicleDocumentEntity> findByVehicleIdAndMandatoryTrue(UUID vehicleId);

  // Bounded per CODING_STANDARDS_BACKEND.md — every history or list query carries a limit so an
  // unbounded scan cannot reach production.
  @Query(
      """
      SELECT d FROM VehicleDocumentEntity d
      WHERE d.mandatory = true AND d.expiresOn <= :cutoff
      ORDER BY d.expiresOn ASC
      """)
  List<VehicleDocumentEntity> findMandatoryExpiringBy(
      @Param("cutoff") LocalDate cutoff, Sort sort, Limit limit);
}
