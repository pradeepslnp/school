package com.guardian.staff.application.port;

import com.guardian.staff.domain.StaffCredential;
import com.guardian.staff.domain.StaffCredentialId;
import com.guardian.staff.domain.StaffId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface StaffCredentialRepository {

  Optional<StaffCredential> findById(StaffCredentialId id);

  List<StaffCredential> findByStaff(StaffId staffId);

  /** Mandatory credentials only — the set BR-STAFF-001 checks at trip start. */
  List<StaffCredential> findMandatoryByStaff(StaffId staffId);

  /**
   * Mandatory credentials expiring within {@code days} of {@code asOf}, bounded per
   * CODING_STANDARDS_BACKEND.md — every history or list query is bounded, never a full scan.
   */
  List<StaffCredential> findMandatoryExpiringWithin(LocalDate asOf, int days, int limit);

  StaffCredential save(StaffCredential credential);
}
