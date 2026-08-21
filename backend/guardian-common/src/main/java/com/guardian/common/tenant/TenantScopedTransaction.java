package com.guardian.common.tenant;

import java.util.function.Supplier;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Runs work in a transaction whose database connection carries a tenant that was resolved, or
 * minted, a moment earlier — rather than one established by the request filter.
 *
 * <p>Every ordinary operation in the platform inherits its tenant from the authenticated principal
 * via {@code TenantContextFilter}, long before any use case runs. This exists for the two shapes of
 * request where that is not true, both of them bootstrap problems:
 *
 * <ul>
 *   <li><strong>Authentication</strong> (guardian-identity). Sign-in is where the tenant is
 *       <em>discovered</em> mid-request — by {@code PreAuthenticationDirectory}, which crosses
 *       tenants once to answer "whose credential is this?" — and everything after that discovery
 *       must run under the tenant it found.
 *   <li><strong>Organization creation</strong> (guardian-tenancy). The organization <em>is</em> the
 *       tenant (ADR-0001), so creating one is where a tenant is <em>minted</em> rather than
 *       discovered: the use case generates the new {@code OrganizationId} first, then must run its
 *       insert under that not-yet-existing tenant's own context for the row's RLS {@code WITH
 *       CHECK} to accept it.
 * </ul>
 *
 * <p>Originally lived in {@code guardian-identity} for the first case alone. Moved here when the
 * second case arrived — the same "resolve or mint a tenant, then transact under it" shape, needed
 * by a module that must not depend on identity to reach it (ENGINEERING_PRINCIPLES.md §6: a pattern
 * used once is not shared infrastructure; a pattern two modules independently need is).
 *
 * <p><strong>The nesting order is the whole point and is easy to get backwards.</strong> {@code
 * TenantAwareDataSource} issues {@code SET LOCAL app.tenant_id} when a connection is handed out,
 * reading {@link TenantContext} at that instant. A transaction acquires its connection as it
 * begins. So the context must be set <em>outside</em> the transaction:
 *
 * <pre>{@code
 * TenantContext.runAs(tenantId, () -> transactionTemplate.execute(...))   // correct
 * transactionTemplate.execute(status -> TenantContext.runAs(tenantId, ...))  // silently broken
 * }</pre>
 *
 * <p>Written the second way, the connection is acquired while the context is still empty, {@code
 * SET LOCAL} never runs, and every statement inside meets an RLS predicate comparing against NULL.
 * Reads return nothing and writes are refused — with no error naming the cause. It looks like a
 * missing row.
 *
 * <p>A programmatic {@link TransactionTemplate} rather than {@code @Transactional} for the same
 * reason: an annotation on a method of the calling class would be applied by a proxy at the call
 * boundary, which is before {@code runAs} has a chance to run.
 */
@Component
public class TenantScopedTransaction {

  private final TransactionTemplate transactionTemplate;

  public TenantScopedTransaction(TransactionTemplate transactionTemplate) {
    this.transactionTemplate = transactionTemplate;
  }

  public <T> T execute(TenantId tenantId, Supplier<T> action) {
    return TenantContext.runAs(tenantId, () -> transactionTemplate.execute(status -> action.get()));
  }
}
