package com.guardian.identity.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.command.UpdateAdministrativeUserCommand;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.port.UserScopeRepository;
import com.guardian.identity.application.result.AdministrativeUserView;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import org.springframework.stereotype.Service;

/**
 * Edits an administrative user's name and locale (feature IAM-005, screen A-43,
 * {@code PERM-USER-EDIT}). See {@code UpdateAdministrativeUserCommand}'s documentation for why
 * role and scope are not editable here.
 */
@Service
public class UpdateAdministrativeUserUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final UserScopeRepository userScopes;
  private final TenantScopedTransaction tenantScoped;

  public UpdateAdministrativeUserUseCase(
      UserRepository users, UserScopeRepository userScopes, TenantScopedTransaction tenantScoped) {
    this.users = users;
    this.userScopes = userScopes;
    this.tenantScoped = tenantScoped;
  }

  public AdministrativeUserView execute(UpdateAdministrativeUserCommand command) {
    if (!SUPER_ADMIN.equals(command.actorRole())) {
      TenantId callerTenant = TenantContext.require();
      if (!callerTenant.value().equals(command.organizationId())) {
        throw new ResourceNotFoundException(
            ErrorCode.AUTH_SCOPE_DENIED, "organization", command.organizationId());
      }
    }

    return tenantScoped.execute(TenantId.of(command.organizationId()), () -> updateWithin(command));
  }

  private AdministrativeUserView updateWithin(UpdateAdministrativeUserCommand command) {
    User existing =
        users
            .findById(UserId.of(command.userId()))
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.USER_NOT_FOUND, "user", command.userId()));

    User updated =
        existing.withProfile(command.firstName(), command.lastName(), command.preferredLocale());
    User saved = users.save(updated);

    return new AdministrativeUserView(
        saved, users.roleCodesOf(saved.id()), userScopes.findByUser(saved.id()));
  }
}
