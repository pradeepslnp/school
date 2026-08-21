package com.guardian.common.tenant;

import java.util.Optional;

/**
 * Holds the tenant for the current request or job.
 *
 * <p>Established once at the edge and propagated implicitly — never passed as a method parameter
 * that a developer could forget to thread through (ENGINEERING_PRINCIPLES.md §9).
 *
 * <p>This holder is a convenience for the application layer. It is <strong>not</strong> the
 * isolation control: that is PostgreSQL row-level security, seeded from this value by {@code SET
 * LOCAL app.tenant_id} at transaction start (ADR-0001). If this holder is empty, RLS returns zero
 * rows rather than every row — the safe default.
 */
public final class TenantContext {

  private static final ThreadLocal<TenantId> CURRENT = new ThreadLocal<>();

  private TenantContext() {}

  /** Returns the current tenant, or empty when no context has been established. */
  public static Optional<TenantId> current() {
    return Optional.ofNullable(CURRENT.get());
  }

  /**
   * Returns the current tenant, failing loudly when absent.
   *
   * <p>Use where the caller genuinely cannot proceed without a tenant. Prefer {@link #current()}
   * where absence is a legitimate state.
   */
  public static TenantId require() {
    TenantId tenantId = CURRENT.get();
    if (tenantId == null) {
      throw new TenantContextMissingException();
    }
    return tenantId;
  }

  public static void set(TenantId tenantId) {
    CURRENT.set(tenantId);
  }

  public static void clear() {
    CURRENT.remove();
  }

  /**
   * Runs {@code action} within the given tenant, restoring the previous context afterwards.
   *
   * <p>The restore matters for nested use — a scheduled job iterating tenants must not leave the
   * last tenant's context behind for whatever runs next on the thread.
   */
  public static <T> T runAs(TenantId tenantId, java.util.function.Supplier<T> action) {
    TenantId previous = CURRENT.get();
    CURRENT.set(tenantId);
    try {
      return action.get();
    } finally {
      if (previous == null) {
        CURRENT.remove();
      } else {
        CURRENT.set(previous);
      }
    }
  }

  public static void runAs(TenantId tenantId, Runnable action) {
    runAs(
        tenantId,
        () -> {
          action.run();
          return null;
        });
  }
}
