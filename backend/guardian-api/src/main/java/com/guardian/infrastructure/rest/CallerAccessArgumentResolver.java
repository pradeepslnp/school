package com.guardian.infrastructure.rest;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.PermissionDeniedException;
import com.guardian.common.security.AccessScope;
import com.guardian.common.security.CallerAccess;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.UserScopeRepository;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserScope;
import com.guardian.infrastructure.security.PermissionEnforcementInterceptor;
import com.guardian.infrastructure.tenant.GuardianPrincipal;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.core.MethodParameter;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

/**
 * Supplies {@link CallerAccess} — the caller's resolved permissions and school scope — to
 * controller methods that must decide per kind of record rather than per endpoint (BR-IAM-004,
 * BR-IAM-006).
 *
 * <p><strong>Permissions are not resolved a second time.</strong> {@link
 * PermissionEnforcementInterceptor} has already resolved them for this request — interceptors run
 * before arguments are resolved — and left the set on the request. Reading it means the endpoint's
 * own gate and the controller's per-kind decisions come from one resolution and cannot disagree. A
 * handler reached without that set, one declaring no {@code @RequiresPermission}, is refused rather
 * than handed an empty set that would look like a caller who simply holds nothing.
 *
 * <p><strong>Scope is read in the caller's home tenant.</strong> {@code user_scopes} is
 * tenant-scoped, and under a platform elevation (ADR-0016) the request acts in the target
 * organization, where the operator has no rows — the same reason the interceptor resolves
 * permissions there. The read runs in its own short transaction under the home tenant and has
 * finished before the controller's work begins in the acting one.
 *
 * <p>Only the current scope counts: {@code user_scopes} is append-and-supersede, and its newest row
 * is the one in force (see {@code JdbcUserScopeRepository}).
 */
@Component
@BusinessRule({"BR-IAM-004", "BR-IAM-006"})
public class CallerAccessArgumentResolver implements HandlerMethodArgumentResolver {

  /** The only role a {@code PLATFORM} scope is honoured for (PERMISSION_MATRIX.md §Roles). */
  private static final String PLATFORM_ROLE = "SUPER_ADMIN";

  private final UserScopeRepository userScopes;
  private final TenantScopedTransaction tenantScoped;

  public CallerAccessArgumentResolver(
      UserScopeRepository userScopes, TenantScopedTransaction tenantScoped) {
    this.userScopes = userScopes;
    this.tenantScoped = tenantScoped;
  }

  @Override
  public boolean supportsParameter(MethodParameter parameter) {
    return CallerAccess.class.equals(parameter.getParameterType());
  }

  @Override
  public Object resolveArgument(
      MethodParameter parameter,
      ModelAndViewContainer mavContainer,
      NativeWebRequest webRequest,
      WebDataBinderFactory binderFactory) {

    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication == null
        || !authentication.isAuthenticated()
        || !(authentication.getPrincipal() instanceof GuardianPrincipal principal)) {
      throw new CurrentActorArgumentResolver.MissingActorException();
    }

    HttpServletRequest request = webRequest.getNativeRequest(HttpServletRequest.class);
    Object granted =
        request == null
            ? null
            : request.getAttribute(PermissionEnforcementInterceptor.GRANTED_PERMISSIONS_ATTRIBUTE);
    if (!(granted instanceof Set<?> permissions)) {
      throw new PermissionDeniedException(
          "CallerAccess is available only on an endpoint that declares @RequiresPermission");
    }

    List<UserScope> scopes =
        tenantScoped.execute(
            principal.tenantId(),
            () -> userScopes.findByUser(UserId.of(principal.actor().userId())));

    return new CallerAccess(
        permissions.stream().map(String::valueOf).collect(Collectors.toUnmodifiableSet()),
        currentScope(scopes, principal.actor().role()));
  }

  private static AccessScope currentScope(List<UserScope> scopes, String role) {
    if (scopes.isEmpty()) {
      return AccessScope.none();
    }
    UserScope current = scopes.get(0);
    return switch (current.level()) {
      // Crossing organizations is a platform operator's alone. A PLATFORM row on any other role
      // is a provisioning error, and fails closed rather than widening.
      case PLATFORM -> PLATFORM_ROLE.equals(role) ? AccessScope.platform() : AccessScope.none();
      case ORG -> AccessScope.wholeOrganization();
      case SCHOOL -> AccessScope.schools(Set.of(current.refId()));
      // A route-scoped account reaches records through its routes and trips, never through a
      // school-wide read — so a school-wide read reaches nothing for it.
      case ROUTE -> AccessScope.none();
    };
  }
}
