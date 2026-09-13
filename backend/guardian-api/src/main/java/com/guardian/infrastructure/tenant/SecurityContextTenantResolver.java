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
 * <p><strong>The tenant comes from the credential.</strong> Reading a tenant from a header,
 * parameter, path segment, or cookie would let any authenticated user address another
 * organization's children, which is the precise attack row-level security exists to stop
 * (BR-TEN-004, ADR-0001).
 *
 * <p><strong>The one exception is {@link PlatformElevation}</strong>, the explicitly permissioned
 * and always-audited platform-operations path BR-TEN-004 itself carves out (ADR-0016). Even there
 * the decision comes from the credential: the request may <em>name</em> a target organization, and
 * only a token proving the platform role may have one honoured. Every other caller is refused, so
 * an attempted escalation fails loudly instead of quietly resolving to its own scope.
 *
 * <p>An unauthenticated request resolves to empty rather than to a default tenant. With no tenant
 * context the RLS session variable is never set, and every tenant-scoped query returns zero rows —
 * the system fails closed. A fallback tenant here would turn a missing credential into full access
 * to somebody's data.
 */
@Component
public class SecurityContextTenantResolver
    implements TenantContextFilter.AuthenticatedTenantResolver {

  private final PlatformElevation elevation;

  public SecurityContextTenantResolver(PlatformElevation elevation) {
    this.elevation = elevation;
  }

  @Override
  public Optional<TenantId> resolve(HttpServletRequest request) {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

    if (authentication == null || !authentication.isAuthenticated()) {
      return Optional.empty();
    }

    // Anonymous authentication is "authenticated" in Spring Security's model but carries no
    // principal of ours, so it must not produce a tenant.
    if (authentication.getPrincipal() instanceof GuardianPrincipal principal) {
      Optional<TenantId> requested = elevation.requestedOrganization(request);

      if (requested.isPresent()) {
        // Authorized before it is honoured, and before any connection is opened — an unauthorized
        // elevation must never reach the point where a tenant variable could be set.
        elevation.authorize(principal.actor());
        return requested;
      }

      return Optional.of(principal.tenantId());
    }

    return Optional.empty();
  }
}
