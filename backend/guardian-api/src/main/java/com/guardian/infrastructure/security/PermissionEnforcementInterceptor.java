package com.guardian.infrastructure.security;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.OrganizationSuspendedException;
import com.guardian.common.error.PermissionDeniedException;
import com.guardian.common.security.RequiresPermission;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.PermissionResolver;
import com.guardian.identity.domain.UserId;
import com.guardian.infrastructure.tenant.GuardianPrincipal;
import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.OrganizationStatus;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.Set;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Enforces {@link RequiresPermission} at request time.
 *
 * <p>The annotation has been declared on endpoints since the first controller, but until now it was
 * read only by an ArchUnit test — the build refused an endpoint that declared no permission, while
 * the running application admitted any authenticated caller to every endpoint regardless of role. A
 * guardian's token could reach staff endpoints. This closes that gap (BR-IAM-002).
 *
 * <h2>Why an interceptor rather than a filter</h2>
 *
 * <p>The required permission is an annotation on a controller method, and which method will handle
 * a request is not known until the {@code DispatcherServlet} has resolved the handler. A filter
 * runs before that and would have to re-derive the mapping itself.
 *
 * <p>Placement is nonetheless safe: the entire security filter chain completes before the {@code
 * DispatcherServlet} is invoked, so {@link SecurityContextHolder} is populated by {@link
 * AccessTokenAuthenticationFilter} and the ambient tenant is set by {@link
 * com.guardian.infrastructure.tenant.TenantContextFilter} before {@code preHandle} runs. Permission
 * resolution is therefore an ordinary tenant-scoped query — not a case for {@code
 * TenantScopedTransaction}, which exists only for the pre-authentication window where no tenant is
 * known yet.
 *
 * <h2>Permissions are resolved, never trusted</h2>
 *
 * <p>The resolver reads current role assignments on every request rather than reading a claim
 * (BR-IAM-004, ADR-0006). A role removed from a user is effective on their next call.
 *
 * <p>Holding the permission is necessary but not sufficient. Object-level scope ({@code
 * OWN_CHILDREN}, {@code SCHOOL}, {@code TRIP}) is a separate check (BR-IAM-006) that use cases
 * still owe: passing here means the caller may perform this kind of action, not that they may
 * perform it on this particular record.
 *
 * <h2>Organization suspension (BR-TEN-006)</h2>
 *
 * <p>Enforced here, after authentication, rather than at login. {@code StaffLoginUseCase}
 * deliberately reports an unknown email, a wrong password, and an inactive account as the same
 * {@code AUTH_CREDENTIALS_INVALID} to prevent email enumeration (BR-IAM-001); a distinctly worded
 * "your organization is suspended" error at login would defeat that specifically for suspended
 * organizations. Checking after the caller is already authenticated closes the same gap with no
 * enumeration surface.
 *
 * <p>Suspension "blocks all user access except platform operations" — it does not stop in-flight
 * safety recording for a trip already started. Rather than integrate with the trip/routes domain
 * to find the exact use-case boundary (not audited as part of this change), {@link
 * #SAFETY_PERMISSION_PREFIXES} allow-lists whole permission families by prefix. This is a
 * deliberately coarse approximation: over-permitting safety-critical operations during a
 * suspension is the safer failure mode than under-permitting them. Worth revisiting with a real
 * audit of the trip domain.
 */
@Component
@BusinessRule({"BR-IAM-002", "BR-IAM-004", "BR-TEN-006"})
public class PermissionEnforcementInterceptor implements HandlerInterceptor {

  /**
   * Permission-ID prefixes that stay enforceable on a suspended organization (BR-TEN-006's
   * in-flight-safety carve-out). See the class Javadoc for why this is prefix-based rather than
   * an exact, individually-reviewed permission list.
   */
  private static final Set<String> SAFETY_PERMISSION_PREFIXES =
      Set.of(
          "PERM-TRIP-",
          "PERM-BOARDING-",
          "PERM-HANDOVER-",
          "PERM-SOS-",
          "PERM-INCIDENT-",
          "PERM-ALERT-",
          "PERM-TRACKING-",
          "PERM-RECONCILIATION-");

  private final PermissionResolver permissionResolver;
  private final OrganizationRepository organizationRepository;

  public PermissionEnforcementInterceptor(
      PermissionResolver permissionResolver, OrganizationRepository organizationRepository) {
    this.permissionResolver = permissionResolver;
    this.organizationRepository = organizationRepository;
  }

  @Override
  public boolean preHandle(
      HttpServletRequest request, HttpServletResponse response, Object handler) {

    if (!(handler instanceof HandlerMethod handlerMethod)) {
      return true;
    }

    RequiresPermission required = handlerMethod.getMethodAnnotation(RequiresPermission.class);
    if (required == null) {
      // Either @PublicEndpoint or not an endpoint at all. EndpointPermissionTest already fails
      // the build for a mapped method carrying neither, so an unannotated handler reaching here
      // is public by decision rather than by omission.
      return true;
    }

    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication == null
        || !(authentication.getPrincipal() instanceof GuardianPrincipal principal)) {
      // Unreachable through the configured chain — anyRequest().authenticated() answers 401
      // first. Kept because the alternative to failing closed here is admitting an unidentified
      // caller if that configuration ever changes.
      throw new PermissionDeniedException(required.value());
    }

    Set<String> granted = permissionResolver.resolve(UserId.of(principal.actor().userId()));
    if (!granted.contains(required.value())) {
      throw new PermissionDeniedException(required.value());
    }

    rejectIfOrganizationSuspended(required.value());

    return true;
  }

  private void rejectIfOrganizationSuspended(String requiredPermission) {
    if (isSafetyPermission(requiredPermission)) {
      return;
    }

    TenantId tenantId = TenantContext.require();
    Organization organization =
        organizationRepository.findById(OrganizationId.of(tenantId.value())).orElse(null);

    // Absent here would mean the caller's own home organization row is unreadable under its
    // own tenant context — a data-integrity problem elsewhere, not a suspension. Fail open on
    // that specific anomaly rather than lock every caller out because of it; the permission
    // check above has already run.
    if (organization != null && organization.status() == OrganizationStatus.SUSPENDED) {
      throw new OrganizationSuspendedException(organization.id().toString());
    }
  }

  private boolean isSafetyPermission(String permission) {
    for (String prefix : SAFETY_PERMISSION_PREFIXES) {
      if (permission.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }
}
