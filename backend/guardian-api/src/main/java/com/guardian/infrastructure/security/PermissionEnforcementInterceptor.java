package com.guardian.infrastructure.security;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.PermissionDeniedException;
import com.guardian.common.security.RequiresPermission;
import com.guardian.identity.application.port.PermissionResolver;
import com.guardian.identity.domain.UserId;
import com.guardian.infrastructure.tenant.GuardianPrincipal;
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
 */
@Component
@BusinessRule({"BR-IAM-002", "BR-IAM-004"})
public class PermissionEnforcementInterceptor implements HandlerInterceptor {

  private final PermissionResolver permissionResolver;

  public PermissionEnforcementInterceptor(PermissionResolver permissionResolver) {
    this.permissionResolver = permissionResolver;
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

    return true;
  }
}
