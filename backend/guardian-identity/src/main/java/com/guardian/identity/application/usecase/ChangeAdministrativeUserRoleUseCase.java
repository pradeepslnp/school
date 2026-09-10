package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.command.ChangeAdministrativeUserRoleCommand;
import com.guardian.identity.application.port.RoleProvisioningPort;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.port.UserScopeRepository;
import com.guardian.identity.application.result.AdministrativeUserView;
import com.guardian.identity.domain.RoleId;
import com.guardian.identity.domain.SystemRoles;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserScope;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;

/**
 * Changes an administrator's role and scope after creation (features IAM-005, IAM-007; screen A-43,
 * {@code PERM-ROLE-MANAGE}).
 *
 * <p>One operation, not three endpoints for grant / revoke / re-scope: an administrative account
 * holds exactly one administrative role at a time, and that role and its scope are a pair (a {@code
 * SCHOOL_ADMIN} is a school-scoped role). So "make this person a {@code TRANSPORT_MANAGER} for
 * Green Valley" is the smallest instruction the screen ever needs to give, and doing it as separate
 * calls would leave the account momentarily holding two roles, or none.
 *
 * <p>Both writes — remove the old administrative grant, add the new — happen in one transaction.
 *
 * <h2>Two checks beyond {@code PERM-ROLE-MANAGE}</h2>
 *
 * <p>Holding the permission (checked by {@code @RequiresPermission} before this runs) says the
 * caller may manage roles; it does not say <em>which</em> role they may grant. {@link
 * SystemRoles#canAssign} is the same product hierarchy {@code CreateAdministrativeUserUseCase}
 * applies at creation, reused here so the two paths cannot diverge. And the role must be one the
 * console administers at all — a {@code DRIVER}/{@code ATTENDANT} system role, or {@code
 * SUPER_ADMIN}, is refused as {@code ROLE_NOT_ASSIGNABLE}.
 *
 * <h2>What this does not touch</h2>
 *
 * <p>Sessions. A role change takes effect on the target's next request regardless — permissions are
 * re-resolved per request, never read from their token (BR-IAM-004). There is no need to end their
 * sessions, and doing so would sign out someone whose access was broadened, not just someone whose
 * access was cut.
 *
 * <p>The custom-role / permission-assignment half of role management (IAM-006) is still not built:
 * this operates only on the nine fixed system-role templates.
 */
@Service
@BusinessRule({"BR-IAM-003", "BR-IAM-006"})
public class ChangeAdministrativeUserRoleUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final UserScopeRepository userScopes;
  private final RoleProvisioningPort roleProvisioning;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public ChangeAdministrativeUserRoleUseCase(
      UserRepository users,
      UserScopeRepository userScopes,
      RoleProvisioningPort roleProvisioning,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.users = users;
    this.userScopes = userScopes;
    this.roleProvisioning = roleProvisioning;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public AdministrativeUserView execute(ChangeAdministrativeUserRoleCommand command) {
    validateRoleAndScope(command);

    if (!SUPER_ADMIN.equals(command.actorRole())) {
      TenantId callerTenant = TenantContext.require();
      if (!callerTenant.value().equals(command.organizationId())) {
        throw new ResourceNotFoundException(
            ErrorCode.AUTH_SCOPE_DENIED, "organization", command.organizationId());
      }
    }

    return tenantScoped.execute(TenantId.of(command.organizationId()), () -> applyWithin(command));
  }

  private void validateRoleAndScope(ChangeAdministrativeUserRoleCommand command) {
    if (!SystemRoles.isAdministrative(command.roleCode())) {
      throw new BusinessRuleViolationException(
          ErrorCode.ROLE_NOT_ASSIGNABLE, "BR-IAM-003", Map.of("roleCode", command.roleCode()));
    }
    if (!SystemRoles.canAssign(command.actorRole(), command.roleCode())) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "role", command.roleCode());
    }
    boolean schoolScoped = SystemRoles.isSchoolScoped(command.roleCode());
    if (schoolScoped && command.schoolId() == null) {
      throw new BusinessRuleViolationException(
          ErrorCode.USER_SCOPE_NOT_PERMITTED_FOR_ROLE,
          "BR-IAM-006",
          Map.of("roleCode", command.roleCode(), "reason", "schoolId required"));
    }
    if (!schoolScoped && command.schoolId() != null) {
      throw new BusinessRuleViolationException(
          ErrorCode.USER_SCOPE_NOT_PERMITTED_FOR_ROLE,
          "BR-IAM-006",
          Map.of("roleCode", command.roleCode(), "reason", "role is organization-wide"));
    }
  }

  private AdministrativeUserView applyWithin(ChangeAdministrativeUserRoleCommand command) {
    TenantId tenantId = TenantId.of(command.organizationId());
    UserId userId = UserId.of(command.userId());

    User user =
        users
            .findById(userId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.USER_NOT_FOUND, "user", command.userId()));

    List<String> currentAdminRoles =
        users.roleCodesOf(userId).stream().filter(SystemRoles::isAdministrative).toList();

    for (String held : currentAdminRoles) {
      if (!held.equals(command.roleCode())) {
        roleProvisioning.revokeSystemRole(tenantId, userId, held);
      }
    }

    RoleId roleId =
        roleProvisioning.findOrCreateSystemRole(
            tenantId, command.roleCode(), SystemRoles.displayName(command.roleCode()));
    roleProvisioning.grantIfMissing(tenantId, userId, roleId);

    UserScope newScope =
        SystemRoles.isSchoolScoped(command.roleCode())
            ? UserScope.school(command.schoolId())
            : UserScope.organization();

    UserScope currentScope = userScopes.findByUser(userId).stream().findFirst().orElse(null);
    if (!Objects.equals(currentScope, newScope)) {
      userScopes.add(tenantId, userId, newScope);
    }

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("ADMINISTRATIVE_USER_ROLE_CHANGED")
            .subject("User", command.userId())
            .before(
                Map.<String, Object>of(
                    "roleCodes",
                    String.join(",", currentAdminRoles),
                    "scopeLevel",
                    currentScope == null ? "" : currentScope.level().name()))
            .after(
                Map.<String, Object>of(
                    "roleCode", command.roleCode(),
                    "scopeLevel", newScope.level().name(),
                    "scopeRefId", newScope.refId() == null ? "" : newScope.refId().toString()))
            .build());

    return new AdministrativeUserView(
        user, users.roleCodesOf(userId), userScopes.findByUser(userId));
  }
}
