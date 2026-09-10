package com.guardian.infrastructure.staff;

import com.guardian.identity.application.port.SessionRepository;
import com.guardian.staff.application.port.StaffSessionRevocationPort;
import com.guardian.staff.domain.UserId;
import org.springframework.stereotype.Component;

/**
 * Implements guardian-staff's {@link StaffSessionRevocationPort} over guardian-identity's session
 * store — the composition root is the one place allowed to see both modules, the same shape as
 * {@link StaffAccountProvisioningAdapter}.
 *
 * <p>Calls {@link SessionRepository#revokeAllForUser} directly rather than through a use case: the
 * caller ({@code DeactivateStaffUseCase}) already holds the transaction and the tenant context, and
 * the audit record for the deactivation — session count included — is written there. A use case
 * here would either duplicate that audit entry or open a nested tenant-scoped transaction, which
 * {@code TenantScopedTransaction} documents as unsafe from inside an existing one.
 */
@Component
class StaffSessionRevocationAdapter implements StaffSessionRevocationPort {

  private final SessionRepository sessions;

  StaffSessionRevocationAdapter(SessionRepository sessions) {
    this.sessions = sessions;
  }

  @Override
  public int revokeAllSessions(UserId userId) {
    return sessions.revokeAllForUser(userId.value(), "STAFF_DEACTIVATED");
  }
}
