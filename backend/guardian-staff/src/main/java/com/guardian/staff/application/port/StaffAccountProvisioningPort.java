package com.guardian.staff.application.port;

import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.UserId;
import java.util.UUID;

/**
 * Gives a newly registered driver or attendant a working sign-in (feature STF-001, completing the
 * activation path {@link com.guardian.staff.domain.TransportStaff#userId()}'s own documentation
 * calls MOD-02 and marks as not yet built).
 *
 * <p>Implemented outside this module, in the composition root (guardian-api), because the real work
 * — creating a {@code users} row and granting a role — belongs to guardian-identity (MOD-02), and
 * this module does not and should not depend on it: every other business module in this backend is
 * reachable only from guardian-api, never from a sibling module, so that each bounded context can
 * be understood, tested, and changed without pulling in the others. Defining the port here and the
 * adapter there is the same dependency-inversion shape as {@link
 * com.guardian.common.audit.AuditPort} and {@code TenantScopedTransaction} elsewhere in this
 * backend, not a new pattern invented for this one case.
 */
public interface StaffAccountProvisioningPort {

  /**
   * Provisions (or reuses, if this phone already has an account in this tenant) the login for a
   * staff member, grants them the role their {@code staffType} implies, and returns the linked
   * user's id.
   */
  UserId provision(
      StaffType staffType,
      String phone,
      String firstName,
      String lastName,
      UUID actorId,
      String actorRole);
}
