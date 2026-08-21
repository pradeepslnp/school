package com.guardian.infrastructure.security;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.AccessTokenVerifier;
import com.guardian.identity.application.port.AccessTokenVerifier.VerifiedToken;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.infrastructure.tenant.GuardianPrincipal;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Optional;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Turns a bearer token into an authenticated principal.
 *
 * <p>Runs before {@link com.guardian.infrastructure.tenant.TenantContextFilter}, which then reads
 * the tenant off the principal this places in the security context. The order is not arbitrary: the
 * tenant must come from the verified token, never from anything else on the request.
 *
 * <p>An absent or unverifiable token leaves the context empty and the chain continues. Rejecting
 * here would answer {@code 401} for every unauthenticated request including the public auth
 * endpoints; refusing access is the security filter chain's job, and it happens a few filters later
 * with the full picture of what the request was for.
 *
 * <h2>Why roles are read from the database on every request</h2>
 *
 * <p>The token carries none (BR-IAM-004, ADR-0006). Resolving them here means a role removed from a
 * user takes effect on their next request rather than whenever their token happens to expire —
 * which, for a staff member who has just been deactivated, is the difference between "immediately"
 * and "up to fifteen minutes of continued access to children's locations".
 *
 * <p>That read is tenant-scoped, and the tenant is only known once the token is verified, so it
 * runs through {@link TenantScopedTransaction} rather than waiting for the tenant filter.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class AccessTokenAuthenticationFilter extends OncePerRequestFilter {

  private static final String BEARER = "Bearer ";

  private final AccessTokenVerifier verifier;
  private final UserRepository users;
  private final TenantScopedTransaction tenantScoped;

  public AccessTokenAuthenticationFilter(
      AccessTokenVerifier verifier, UserRepository users, TenantScopedTransaction tenantScoped) {
    this.verifier = verifier;
    this.users = users;
    this.tenantScoped = tenantScoped;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {

    try {
      authenticate(request);
      filterChain.doFilter(request, response);
    } finally {
      // Thread pools reuse threads. A context left behind would be inherited by whatever
      // request runs next on this one — the same reason TenantContextFilter clears its own.
      SecurityContextHolder.clearContext();
    }
  }

  private void authenticate(HttpServletRequest request) {
    Optional<String> token = bearerToken(request);
    if (token.isEmpty()) {
      return;
    }

    Optional<VerifiedToken> verified = verifier.verify(token.get());
    if (verified.isEmpty()) {
      return;
    }

    VerifiedToken claims = verified.get();

    List<String> roles =
        tenantScoped.execute(claims.tenantId(), () -> users.roleCodesOf(claims.userId()));

    if (roles.isEmpty()) {
      // Deny by default (BR-IAM-002). A user holding no role can do nothing, so leaving the
      // context unauthenticated is both correct and the only honest option — CurrentActor
      // records the role held at the time for the audit trail, and inventing one here would
      // put a fiction into evidence.
      return;
    }

    // The first role, for the audit trail's "role held at the time" (BR-AUD-003). A user with
    // several roles is recorded under one; permission checks, when they are built, resolve the
    // full set at the point of the check rather than relying on this.
    CurrentActor actor = CurrentActor.of(claims.userId().value(), roles.get(0));

    UsernamePasswordAuthenticationToken authentication =
        UsernamePasswordAuthenticationToken.authenticated(
            new GuardianPrincipal(actor, claims.tenantId()), null, List.of());

    SecurityContextHolder.getContext().setAuthentication(authentication);
  }

  private static Optional<String> bearerToken(HttpServletRequest request) {
    String header = request.getHeader("Authorization");
    if (header == null || !header.startsWith(BEARER)) {
      return Optional.empty();
    }
    String value = header.substring(BEARER.length()).trim();
    return value.isEmpty() ? Optional.empty() : Optional.of(value);
  }
}
