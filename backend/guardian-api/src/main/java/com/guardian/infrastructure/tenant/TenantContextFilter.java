package com.guardian.infrastructure.tenant;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.PermissionDeniedException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Instant;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.HandlerExceptionResolver;

/**
 * Establishes tenant context once per request, from the authenticated principal.
 *
 * <p>Runs immediately after authentication and before anything that touches the database. Putting
 * this in a filter rather than in each query is the whole point: a developer cannot forget it
 * (ENGINEERING_PRINCIPLES.md §9).
 *
 * <p><strong>The tenant comes from the token.</strong> A client-supplied tenant would let any
 * authenticated user address any organization's data — exactly the attack row-level security exists
 * to stop.
 *
 * <p>The single exception is {@link PlatformElevation} (ADR-0016): a request may <em>name</em> a
 * target organization, and only a token proving the {@code SUPER_ADMIN} role has one honoured. That
 * is BR-TEN-004's own carve-out, and it is audited here rather than trusted.
 *
 * <p>The {@code finally} block is not optional. Thread pools reuse threads, so a context left
 * behind would be inherited by whatever request runs next on that thread.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 20)
public class TenantContextFilter extends OncePerRequestFilter {

  private final AuthenticatedTenantResolver tenantResolver;
  private final PlatformElevation elevation;
  private final AuditPort audit;
  private final TransactionTemplate transactions;
  private final HandlerExceptionResolver exceptionResolver;

  public TenantContextFilter(
      AuthenticatedTenantResolver tenantResolver,
      PlatformElevation elevation,
      AuditPort audit,
      PlatformTransactionManager transactionManager,
      @Qualifier("handlerExceptionResolver") HandlerExceptionResolver exceptionResolver) {
    this.tenantResolver = tenantResolver;
    this.elevation = elevation;
    this.audit = audit;
    this.transactions = new TransactionTemplate(transactionManager);
    this.exceptionResolver = exceptionResolver;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    // One finally for every exit, the refusal below included: a context left behind would be
    // inherited by whatever request next runs on this pooled thread.
    try {
      try {
        tenantResolver.resolve(request).ifPresent(TenantContext::set);
        recordElevation(request);
      } catch (PermissionDeniedException e) {
        // A refused elevation is thrown before the request reaches a controller, so it never
        // passes through the @ControllerAdvice that maps domain failures to the documented
        // envelope (ERROR_CATALOG.md). Routing it through the same resolver keeps one envelope
        // implementation: without this the caller gets a misleading 401 from further down the
        // chain rather than the permission error that actually occurred.
        exceptionResolver.resolveException(request, response, null, e);
        return;
      }

      filterChain.doFilter(request, response);
    } finally {
      TenantContext.clear();
    }
  }

  /**
   * Writes the audit record BR-AUD-005 requires for a platform operator crossing an organization
   * boundary.
   *
   * <p>Written <em>after</em> the context is established and <em>before</em> the request runs, for
   * two reasons. The audit table is itself tenant-scoped, so the insert needs {@code app.tenant_id}
   * already set — and it lands in the target organization's own trail, which is where someone
   * asking "who outside this organization touched our records" will look. Recording before the
   * request means an elevated call that then fails is still recorded: the access was attempted
   * either way, and an audit trail that only lists successes is not one.
   *
   * <p>This records the crossing itself. Changes made under it write their own audit records
   * through the ordinary use-case paths, in the same transaction as the change (BR-AUD-002), so a
   * reviewer sees both the door being opened and what was done inside.
   *
   * <p><strong>Why this opens its own transaction.</strong> {@code AuditPort} is {@code
   * Propagation.MANDATORY} so that no audit record can ever commit independently of the change it
   * describes. A filter has no ambient transaction, so the write needs one — and giving it its own
   * respects rather than evades that rule: the event being recorded here <em>is</em> the crossing,
   * not some other change this record could become detached from. The crossing is a fact the moment
   * the context is set, whatever the request goes on to do.
   *
   * <p>Every elevated request produces a row, reads included. That is deliberately noisy: an
   * operator reaching into a tenant's child records is a rare and significant act, and sampling it
   * would defeat the rule.
   */
  private void recordElevation(HttpServletRequest request) {
    Optional<TenantId> elevated = elevation.requestedOrganization(request);
    if (elevated.isEmpty()) {
      return;
    }

    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (!(authentication != null
        && authentication.getPrincipal() instanceof GuardianPrincipal principal)) {
      return;
    }

    TenantId target = elevated.get();

    transactions.executeWithoutResult(
        status ->
            audit.record(
                AuditRecord.builder()
                    .tenantId(target)
                    .actor(
                        principal.actor().userId(),
                        AuditRecord.ActorType.PLATFORM_OPERATOR,
                        principal.actor().role())
                    .action("PLATFORM_ORG_ELEVATION")
                    .subject("ORGANIZATION", target.value())
                    .source(AuditRecord.Source.PLATFORM_OPS)
                    // The request line is the reason: it records exactly what the operator reached
                    // for,
                    // which is the question an auditor asks of a cross-organization access.
                    .reason("%s %s".formatted(request.getMethod(), request.getRequestURI()))
                    .occurredAt(Instant.now())
                    .build()));
  }

  /** Resolves the tenant from the authenticated session. */
  public interface AuthenticatedTenantResolver {
    java.util.Optional<TenantId> resolve(HttpServletRequest request);
  }
}
