package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.DataConflictException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.command.CreateAdministrativeUserCommand;
import com.guardian.identity.application.port.PasswordCredentialRepository;
import com.guardian.identity.application.port.RoleProvisioningPort;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.port.UserScopeRepository;
import com.guardian.identity.application.result.AdministrativeUserView;
import com.guardian.identity.domain.PasswordCredential;
import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.RoleId;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserScope;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Creates a login for a person who administers an organization or school (feature IAM-005,
 * IAM-008; screen A-43) — an {@code ORG_ADMIN}, {@code SCHOOL_ADMIN}, {@code PRINCIPAL}, or {@code
 * TRANSPORT_MANAGER}.
 *
 * <p>Deliberately a separate class from {@link ProvisionStaffAccountUseCase}, not an overload of
 * it, even though both mint a user and grant a role. That use case's own Javadoc scopes it to
 * "a newly registered driver or attendant" (feature STF-001) — a phone-and-OTP account with no
 * password. This one creates the opposite shape: email and password, the credential {@code
 * StaffLoginUseCase} checks, because that is how every admin console role signs in. Reusing one
 * method for both would mean every caller handles a credential kind that cannot apply to it.
 *
 * <h2>Why the caller always supplies {@code organizationId}</h2>
 *
 * <p>Closing the gap this use case exists to close: before it, {@code POST /organizations} minted
 * an Organization + School with no account for anyone to administer them, so every onboarded
 * organization was unusable by its own staff. Creating that first account can come from a {@code
 * SUPER_ADMIN} who does not belong to the target organization's tenant at all — the same
 * structural problem {@link com.guardian.tenancy.application.usecase.CreateOrganizationUseCase}
 * and {@code UpdateOrganizationUseCase} solve with {@link TenantScopedTransaction}, applied here
 * for the same reason.
 *
 * <h2>Two checks this use case makes that the permission system does not</h2>
 *
 * <p>Holding {@code PERM-USER-CREATE} (checked by {@code @RequiresPermission} before this class is
 * even reached) says nothing about <em>which role</em> the caller may grant, or to which scope
 * (BR-IAM-006 — permission answers "what", scope answers "which"). Nothing in
 * PERMISSION_MATRIX.md spells out a role hierarchy for account creation, so {@link
 * #ASSIGNABLE_ROLES} is a product decision made here: a {@code SUPER_ADMIN} may create an {@code
 * ORG_ADMIN} for any organization, or — so a platform operator can finish onboarding a customer
 * without waiting on that customer's own admin — a school-scoped role directly; an {@code
 * ORG_ADMIN} may create school-scoped roles within their own organization; a {@code SCHOOL_ADMIN}
 * may create {@code PRINCIPAL}/{@code TRANSPORT_MANAGER} within their own school.
 *
 * <h2>A known, deliberate gap</h2>
 *
 * <p>The organization-boundary check below compares {@code organizationId} against the caller's
 * own {@link TenantContext} for anyone but a {@code SUPER_ADMIN}. It does not additionally verify
 * that a {@code SCHOOL_ADMIN}'s {@code schoolId} is their <em>own</em> school rather than another
 * one in the same organization — {@code CurrentActor} carries a role, not a resolved scope, so
 * that check is not available this cheaply yet. This is the same category of gap {@code
 * UpdateOrganizationUseCase} documents about itself rather than silently leaving unstated: it adds
 * no new exposure relative to every other use case in this codebase today, but it does not close
 * the existing one either.
 */
@Service
@BusinessRule({"BR-IAM-002", "BR-IAM-004", "BR-IAM-006"})
public class CreateAdministrativeUserUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private static final Map<String, Set<String>> ASSIGNABLE_ROLES =
      Map.of(
          "SUPER_ADMIN",
              Set.of("ORG_ADMIN", "SCHOOL_ADMIN", "PRINCIPAL", "TRANSPORT_MANAGER"),
          "ORG_ADMIN",
              Set.of("SCHOOL_ADMIN", "PRINCIPAL", "TRANSPORT_MANAGER"),
          "SCHOOL_ADMIN",
              Set.of("PRINCIPAL", "TRANSPORT_MANAGER"));

  private static final Set<String> SCHOOL_SCOPED_ROLES =
      Set.of("SCHOOL_ADMIN", "PRINCIPAL", "TRANSPORT_MANAGER");

  private final UserRepository users;
  private final UserScopeRepository userScopes;
  private final RoleProvisioningPort roleProvisioning;
  private final PasswordCredentialRepository passwordCredentials;
  private final SecretHasher secretHasher;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public CreateAdministrativeUserUseCase(
      UserRepository users,
      UserScopeRepository userScopes,
      RoleProvisioningPort roleProvisioning,
      PasswordCredentialRepository passwordCredentials,
      SecretHasher secretHasher,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.users = users;
    this.userScopes = userScopes;
    this.roleProvisioning = roleProvisioning;
    this.passwordCredentials = passwordCredentials;
    this.secretHasher = secretHasher;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public AdministrativeUserView execute(CreateAdministrativeUserCommand command) {
    Set<String> assignable = ASSIGNABLE_ROLES.getOrDefault(command.actorRole(), Set.of());
    if (!assignable.contains(command.roleCode())) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "role", command.roleCode());
    }

    boolean schoolScoped = SCHOOL_SCOPED_ROLES.contains(command.roleCode());
    if (schoolScoped && command.schoolId() == null) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "school", "*");
    }
    if (!schoolScoped && command.schoolId() != null) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "organization", "*");
    }

    // Checked against the caller's OWN ambient tenant, before TenantScopedTransaction switches
    // context below — TenantContext.require() after that point would answer with the target
    // organization, not the caller's, and this check would always pass.
    if (!SUPER_ADMIN.equals(command.actorRole())) {
      TenantId callerTenant = TenantContext.require();
      if (!callerTenant.value().equals(command.organizationId())) {
        throw new ResourceNotFoundException(
            ErrorCode.AUTH_SCOPE_DENIED, "organization", command.organizationId());
      }
    }

    return tenantScoped.execute(TenantId.of(command.organizationId()), () -> createWithin(command));
  }

  private AdministrativeUserView createWithin(CreateAdministrativeUserCommand command) {
    String email = command.email().trim();

    if (users.findByEmail(email).isPresent()) {
      throw new DataConflictException(ErrorCode.USER_EMAIL_EXISTS, Map.of("field", "email"));
    }

    PhoneNumber phone = parsePhoneOrNull(command.phone());

    User created =
        users.create(
            User.createAdministrative(
                UserId.of(UUID.randomUUID()),
                email,
                phone,
                command.firstName(),
                command.lastName(),
                "en"));

    TenantId tenantId = TenantId.of(command.organizationId());

    RoleId roleId =
        roleProvisioning.findOrCreateSystemRole(tenantId, command.roleCode(), roleName(command.roleCode()));
    roleProvisioning.grantIfMissing(tenantId, created.id(), roleId);

    UserScope scope =
        SCHOOL_SCOPED_ROLES.contains(command.roleCode())
            ? UserScope.school(command.schoolId())
            : UserScope.organization();
    userScopes.add(tenantId, created.id(), scope);

    passwordCredentials.save(
        PasswordCredential.issue(created.id(), secretHasher.hash(command.initialPassword())));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("ADMINISTRATIVE_USER_CREATED")
            .subject("User", created.id().value())
            .after(
                Map.<String, Object>of(
                    "roleCode", command.roleCode(),
                    "email", maskEmail(email),
                    "scopeLevel", scope.level().name()))
            .build());

    return new AdministrativeUserView(created, List.of(command.roleCode()), List.of(scope));
  }

  private static PhoneNumber parsePhoneOrNull(String raw) {
    if (raw == null || raw.isBlank()) {
      return null;
    }
    try {
      return PhoneNumber.of(raw);
    } catch (IllegalArgumentException e) {
      throw new ResourceNotFoundException(ErrorCode.VALIDATION_INVALID_FORMAT, "phone", raw);
    }
  }

  private static String roleName(String roleCode) {
    return switch (roleCode) {
      case "ORG_ADMIN" -> "Organization Admin";
      case "SCHOOL_ADMIN" -> "School Admin";
      case "PRINCIPAL" -> "Principal";
      case "TRANSPORT_MANAGER" -> "Transport Manager";
      default -> roleCode;
    };
  }

  /** {@code first@example.com} → {@code f***@example.com}, matching StaffLoginUseCase. */
  private static String maskEmail(String email) {
    int at = email.indexOf('@');
    if (at <= 0) {
      return "***";
    }
    return email.charAt(0) + "***" + email.substring(at);
  }
}
