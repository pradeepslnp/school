package com.guardian.fleet.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository. Package-private — callers use {@link
 * com.guardian.fleet.application.port.VehicleRepository} via {@link VehicleRepositoryAdapter}.
 *
 * <p>No query here filters on {@code tenant_id}: row-level security applies that predicate to every
 * statement (ADR-0001). {@link #existsByRegistrationNo} is safe for the BR-FLEET-001 uniqueness
 * check specifically <em>because</em> of that — RLS already confines it to the calling tenant, so
 * "unique within the organization" falls out of "unique among rows I can see."
 */
interface VehicleJpaRepository extends JpaRepository<VehicleEntity, UUID> {

  List<VehicleEntity> findBySchoolIdOrderByDisplayName(UUID schoolId);

  boolean existsByRegistrationNo(String registrationNo);
}
