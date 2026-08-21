package com.guardian.infrastructure.tenant;

import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Establishes tenant context once per request, from the authenticated principal.
 *
 * <p>Runs immediately after authentication and before anything that touches the database. Putting
 * this in a filter rather than in each query is the whole point: a developer cannot forget it
 * (ENGINEERING_PRINCIPLES.md §9).
 *
 * <p><strong>The tenant comes from the token, never from a header or parameter.</strong> A
 * client-supplied tenant would let any authenticated user address any organization's data — exactly
 * the attack row-level security exists to stop.
 *
 * <p>The {@code finally} block is not optional. Thread pools reuse threads, so a context left
 * behind would be inherited by whatever request runs next on that thread.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 20)
public class TenantContextFilter extends OncePerRequestFilter {

  private final AuthenticatedTenantResolver tenantResolver;

  public TenantContextFilter(AuthenticatedTenantResolver tenantResolver) {
    this.tenantResolver = tenantResolver;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    try {
      tenantResolver.resolve(request).ifPresent(TenantContext::set);
      filterChain.doFilter(request, response);
    } finally {
      TenantContext.clear();
    }
  }

  /** Resolves the tenant from the authenticated session. */
  public interface AuthenticatedTenantResolver {
    java.util.Optional<TenantId> resolve(HttpServletRequest request);
  }
}
