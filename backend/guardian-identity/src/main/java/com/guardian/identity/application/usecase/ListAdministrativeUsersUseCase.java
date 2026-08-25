package com.guardian.identity.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.port.UserScopeRepository;
import com.guardian.identity.application.result.AdministrativeUserView;
import com.guardian.identity.domain.User;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Lists the administrative accounts (ORG_ADMIN/SCHOOL_ADMIN/PRINCIPAL/TRANSPORT_MANAGER) within
 * one organization, for the Users screen (A-43, feature IAM-005, IAM-008).
 *
 * <p>Bootstraps into the target organization's tenant via {@link TenantScopedTransaction} the same
 * way {@link CreateAdministrativeUserUseCase} does, and for the same reason: a {@code SUPER_ADMIN}
 * browsing an organization they onboarded is not, themselves, a member of that organization's
 * tenant. {@code ORG_ADMIN}/{@code SCHOOL_ADMIN} may only ever list their own organization's users
 * — enforced below, before the bootstrap switches {@link TenantContext} away from their real one,
 * matching {@code CreateAdministrativeUserUseCase}'s identical ordering requirement.
 */
@Service
public class ListAdministrativeUsersUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final UserScopeRepository userScopes;
  private final TenantScopedTransaction tenantScoped;

  public ListAdministrativeUsersUseCase(
      UserRepository users, UserScopeRepository userScopes, TenantScopedTransaction tenantScoped) {
    this.users = users;
    this.userScopes = userScopes;
    this.tenantScoped = tenantScoped;
  }

  public List<AdministrativeUserView> execute(UUID organizationId, String actorRole) {
    if (!SUPER_ADMIN.equals(actorRole)) {
      TenantId callerTenant = TenantContext.require();
      if (!callerTenant.value().equals(organizationId)) {
        throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "organization", organizationId);
      }
    }

    return tenantScoped.execute(TenantId.of(organizationId), this::listWithin);
  }

  private List<AdministrativeUserView> listWithin() {
    return users.findAdministrativeUsers().stream()
        .map(
            (User user) ->
                new AdministrativeUserView(
                    user, users.roleCodesOf(user.id()), userScopes.findByUser(user.id())))
        .toList();
  }
}
