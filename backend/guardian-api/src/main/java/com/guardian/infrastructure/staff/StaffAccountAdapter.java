package com.guardian.infrastructure.staff;

import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.usecase.ReleaseAccountRoleUseCase;
import com.guardian.staff.application.port.StaffAccountPort;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.UserId;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Implements guardian-staff's {@link StaffAccountPort} over guardian-identity — the composition
 * root is the one place allowed to see both modules, the same shape as {@link
 * StaffAccountProvisioningAdapter}.
 *
 * <p>{@link #hasSignedIn} reads the account through {@link UserRepository} directly, for the reason
 * {@link StaffSessionRevocationAdapter} gives: the caller already holds the transaction and the
 * tenant context. {@link #release} goes through {@link ReleaseAccountRoleUseCase}, which is written
 * to run inside that same transaction and records the account's side of the audit trail itself.
 */
@Component
class StaffAccountAdapter implements StaffAccountPort {

  private final UserRepository users;
  private final ReleaseAccountRoleUseCase releaseAccountRole;

  StaffAccountAdapter(UserRepository users, ReleaseAccountRoleUseCase releaseAccountRole) {
    this.users = users;
    this.releaseAccountRole = releaseAccountRole;
  }

  /**
   * {@code last_login_at} is set on every successful sign-in, OTP and password alike. No account
   * row means nothing can have been recorded under it.
   */
  @Override
  public boolean hasSignedIn(UserId userId) {
    return users
        .findById(com.guardian.identity.domain.UserId.of(userId.value()))
        .map(user -> user.lastLoginAt() != null)
        .orElse(false);
  }

  @Override
  public String release(
      UserId userId, StaffType staffType, String reasonCode, UUID actorId, String actorRole) {
    return releaseAccountRole
        .execute(
            userId.value(),
            StaffAccountProvisioningAdapter.roleCodeFor(staffType),
            reasonCode,
            actorId,
            actorRole)
        .name();
  }
}
