package com.guardian.guardian.application.port;

import java.util.UUID;

/**
 * Gives a guardian a working sign-in (features GRD-001, IAM-002).
 *
 * <p>Implemented outside this module, in the composition root (guardian-api), because the real work
 * — creating a {@code users} row and granting the {@code GUARDIAN} role — belongs to
 * guardian-identity (MOD-02), and this module does not and should not depend on it. Defining the
 * port here and the adapter there is the same dependency-inversion shape as guardian-staff's {@code
 * StaffAccountProvisioningPort}, {@code AuditPort}, and {@code TenantScopedTransaction} — not a new
 * pattern invented for this case.
 *
 * <p>Returns the linked user's id as a plain {@code UUID}: this module stores it on {@code
 * guardians.user_id} as a UUID and needs nothing more from identity's own {@code UserId} type.
 */
public interface GuardianAccountProvisioningPort {

  /**
   * Provisions (or reuses, if this phone already has an account in this tenant) the login for a
   * guardian, grants the {@code GUARDIAN} role, and returns the linked user's id. Idempotent by
   * phone within the tenant — a parent of siblings, or a parent who is also staff here, keeps one
   * account (BR-IAM-003).
   */
  UUID provision(String phone, String firstName, String lastName, UUID actorId, String actorRole);
}
