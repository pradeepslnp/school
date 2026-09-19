package com.guardian.staff.infrastructure.persistence;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Package-private — callers use {@link
 * com.guardian.staff.application.port.StaffCredentialRepository} via {@link
 * StaffCredentialRepositoryAdapter}.
 */
interface StaffCredentialJpaRepository extends JpaRepository<StaffCredentialEntity, UUID> {

  List<StaffCredentialEntity> findByStaffId(UUID staffId);

  List<StaffCredentialEntity> findByStaffIdAndMandatoryTrue(UUID staffId);

  // Bounded per CODING_STANDARDS_BACKEND.md — every history or list query carries a limit so an
  // unbounded scan cannot reach production.
  @Query(
      """
      SELECT c FROM StaffCredentialEntity c
      WHERE c.mandatory = true AND c.expiresOn <= :cutoff
      ORDER BY c.expiresOn ASC
      """)
  List<StaffCredentialEntity> findMandatoryExpiringBy(
      @Param("cutoff") LocalDate cutoff, Sort sort, Limit limit);

  @Modifying(flushAutomatically = true)
  @Query("DELETE FROM StaffCredentialEntity c WHERE c.staffId = :staffId")
  int deleteAllByStaffId(@Param("staffId") UUID staffId);
}
