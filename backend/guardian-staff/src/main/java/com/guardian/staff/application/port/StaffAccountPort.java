package com.guardian.staff.application.port;

import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.UserId;
import java.util.UUID;

/**
 * What a staff record needs to know about, and do to, the sign-in account linked to it once that
 * account is no longer the right one — a phone was corrected, or the record is being discarded
 * (BR-IAM-014, BR-STAFF-007, ADR-0019).
 *
 * <p>Implemented in the composition root over guardian-identity, for the same dependency-inversion
 * reason as {@link StaffAccountProvisioningPort}. Runs inside the caller's transaction and tenant.
 */
public interface StaffAccountPort {

  /**
   * Whether the account has ever signed in. An account that has may have recorded events under it,
   * which is history a discard must not orphan.
   */
  boolean hasSignedIn(UserId userId);

  /**
   * Takes the role {@code staffType} implies back from the account, revokes every session it holds,
   * and leaves it inactive if no role remains. Never deletes the account.
   *
   * @param reasonCode why, for the audit trail — e.g. {@code PHONE_CORRECTED}, {@code
   *     STAFF_DISCARDED}
   * @return what happened to the account, as recorded on the audit trail
   */
  String release(
      UserId userId, StaffType staffType, String reasonCode, UUID actorId, String actorRole);
}
