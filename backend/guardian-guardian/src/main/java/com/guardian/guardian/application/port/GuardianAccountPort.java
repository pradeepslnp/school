package com.guardian.guardian.application.port;

import java.util.UUID;

/**
 * What a guardian record does to the sign-in account it no longer points at, once a phone
 * correction has moved it to the new number's account (BR-IAM-014, ADR-0019).
 *
 * <p>Implemented in the composition root over guardian-identity, for the same dependency-inversion
 * reason as {@link GuardianAccountProvisioningPort}. Runs inside the caller's transaction and
 * tenant.
 */
public interface GuardianAccountPort {

  /**
   * Takes the {@code GUARDIAN} role back from the account, revokes every session it holds, and
   * leaves it inactive if no role remains. Never deletes the account.
   *
   * @param reasonCode why, for the audit trail — e.g. {@code PHONE_CORRECTED}
   * @return what happened to the account, as recorded on the audit trail
   */
  String release(UUID userId, String reasonCode, UUID actorId, String actorRole);
}
