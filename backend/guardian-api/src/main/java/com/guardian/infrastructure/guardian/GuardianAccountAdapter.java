package com.guardian.infrastructure.guardian;

import com.guardian.guardian.application.port.GuardianAccountPort;
import com.guardian.identity.application.usecase.ReleaseAccountRoleUseCase;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Implements guardian-guardian's {@link GuardianAccountPort} over guardian-identity's {@link
 * ReleaseAccountRoleUseCase} — the composition root is the one place allowed to see both modules.
 * Same shape as {@code StaffAccountAdapter}; the release use case runs inside the caller's
 * transaction and records the account's side of the audit trail itself.
 */
@Component
class GuardianAccountAdapter implements GuardianAccountPort {

  /** The role {@code ProvisionGuardianAccountUseCase} grants (PERMISSION_MATRIX.md). */
  private static final String GUARDIAN_ROLE_CODE = "GUARDIAN";

  private final ReleaseAccountRoleUseCase releaseAccountRole;

  GuardianAccountAdapter(ReleaseAccountRoleUseCase releaseAccountRole) {
    this.releaseAccountRole = releaseAccountRole;
  }

  @Override
  public String release(UUID userId, String reasonCode, UUID actorId, String actorRole) {
    return releaseAccountRole
        .execute(userId, GUARDIAN_ROLE_CODE, reasonCode, actorId, actorRole)
        .name();
  }
}
