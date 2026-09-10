package com.guardian.guardian.application.port;

import com.guardian.guardian.domain.CustodyRestriction;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for {@code custody_restrictions} (MOD-04, feature GRD-006).
 *
 * <p>Tenant-scoped by row-level security, so no {@code tenant_id} appears in the SQL. There is no
 * delete: a restriction that was in force and then lifted is part of the record — {@link #lift}
 * deactivates it.
 */
public interface CustodyRestrictionRepository {

  /** Every restriction on a student, active and lifted, newest first — the A-14 list. */
  List<CustodyRestriction> findAllForStudent(UUID studentId);

  Optional<CustodyRestriction> findById(UUID id);

  CustodyRestriction save(CustodyRestriction restriction, UUID actorUserId);

  /** Marks a restriction lifted. Immediate; never a delete. */
  void lift(UUID id, UUID actorUserId);

  /**
   * Whether the guardian id, if given, is a real guardian on file within the tenant — so the screen
   * cannot restrict a guardian that does not exist.
   */
  boolean guardianExists(UUID guardianId);
}
