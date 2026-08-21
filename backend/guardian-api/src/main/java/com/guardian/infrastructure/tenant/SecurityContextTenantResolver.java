package com.guardian.infrastructure.tenant;

import com.guardian.common.tenant.TenantId;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Optional;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
 * Resolves the tenant from the authenticated principal in the security context.
 *
 * <p><strong>The request is never consulted.</strong> The {@link HttpServletRequest} parameter is
 * part of the port's shape but is deliberately unused: reading a header, parameter, path segment,
 * or cookie would let any authenticated user address another organization's children, which is the
 * precise attack row-level security exists to stop (BR-TEN-004, ADR-0001).
 *
 * <p>An unauthenticated request resolves to empty rather than to a default tenant. With no tenant
 * context the RLS session variable is never set, and every tenant-scoped query returns zero rows —
 * the system fails closed. A fallback tenant here would turn a missing credential into full access
 * to somebody's data.
 */
@Component
public class SecurityContextTenantResolver
    implements TenantContextFilter.AuthenticatedTenantResolver {

  @Override
  public Optional<TenantId> resolve(HttpServletRequest request) {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

    if (authentication == null || !authentication.isAuthenticated()) {
      return Optional.empty();
    }

    // Anonymous authentication is "authenticated" in Spring Security's model but carries no
    // principal of ours, so it must not produce a tenant.
    if (authentication.getPrincipal() instanceof GuardianPrincipal principal) {
      return Optional.of(principal.tenantId());
    }

    return Optional.empty();
  }
}
