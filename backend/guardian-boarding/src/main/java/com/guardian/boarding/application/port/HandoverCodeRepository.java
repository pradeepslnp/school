package com.guardian.boarding.application.port;

import com.guardian.boarding.domain.HandoverCode;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for handover verification codes, in the domain's language rather than the table's.
 */
public interface HandoverCodeRepository {

  /**
   * Marks any live (unredeemed, unexpired) code for this student as superseded, then inserts and
   * returns the new one — the "I reopened the screen" case is a replacement, not a second valid
   * code in circulation.
   */
  HandoverCode issue(HandoverCode code, UUID actorUserId);

  /**
   * Whether the calling user is a guardian of this student holding {@code can_authorise_handover}.
   *
   * <p>{@code PERM-HANDOVER-CODE-REQUEST} is necessary and never sufficient — object-level scope is
   * exactly what an endpoint permission cannot express (BR-GRD-006, PERMISSION_MATRIX.md). Mirrors
   * {@code PickupPersonRepository.nominatingGuardianIdFor} in MOD-04, which checks the same
   * underlying right for a different action.
   */
  Optional<UUID> authorisingGuardianIdFor(UUID userId, UUID studentId);
}
