package com.guardian.staff.application.port;

import com.guardian.staff.domain.UserId;

/**
 * Ends every live session held by the login linked to a staff record — what deactivating a driver
 * or attendant must do at once (BR-IAM-008): a dismissed driver keeping access to children's live
 * locations until a token expires is the exact failure this rule exists to prevent.
 *
 * <p>Implemented in the composition root (guardian-api) over guardian-identity's session store, for
 * the same dependency-inversion reason as {@link StaffAccountProvisioningPort} — this module does
 * not depend on identity. Runs inside the caller's transaction and tenant context (deactivation is
 * always a caller acting within their own organisation), so it is a plain repository call there,
 * not a nested tenant-scoped transaction.
 */
public interface StaffSessionRevocationPort {

  /**
   * Revokes all of {@code userId}'s sessions and returns how many were live.
   *
   * @param userId the {@code users} row linked to the staff record ({@code TransportStaff.userId})
   */
  int revokeAllSessions(UserId userId);
}
