package com.guardian.common.security;

import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Which schools a caller's reads may reach (BR-IAM-006).
 *
 * <p>Resolved server-side from the caller's current {@code user_scopes} row, never from the
 * request:
 *
 * <ul>
 *   <li>{@code PLATFORM}, held by a {@code SUPER_ADMIN}, reaches every school in the organization a
 *       request acts in — and, for the few reads that explicitly support it, every organization at
 *       once ({@link #platformWide}; the platform-wide search, ADR-0018, which audits each
 *       organization it shows).
 *   <li>{@code ORG} reaches every school in the acting organization.
 *   <li>{@code SCHOOL} reaches the named school.
 *   <li>Anything else — a {@code ROUTE}-scoped account, one with no scope recorded, or a {@code
 *       PLATFORM} scope held by any role but {@code SUPER_ADMIN} — reaches no school at all. An
 *       unresolvable scope fails closed rather than widening.
 * </ul>
 *
 * <p>Row-level security remains the tenant boundary for every read that is not explicitly
 * platform-wide.
 */
public record AccessScope(boolean platformWide, boolean organizationWide, Set<UUID> schoolIds) {

  private static final AccessScope NONE = new AccessScope(false, false, Set.of());
  private static final AccessScope WHOLE_ORGANIZATION = new AccessScope(false, true, Set.of());
  private static final AccessScope PLATFORM = new AccessScope(true, true, Set.of());

  public AccessScope {
    schoolIds = Set.copyOf(Objects.requireNonNull(schoolIds, "schoolIds"));
  }

  /** Reaches no school. */
  public static AccessScope none() {
    return NONE;
  }

  /** Reaches every school in the organization the request acts in. */
  public static AccessScope wholeOrganization() {
    return WHOLE_ORGANIZATION;
  }

  /**
   * A platform operator's scope: every school in the acting organization, and every organization
   * for a read that explicitly supports crossing them.
   */
  public static AccessScope platform() {
    return PLATFORM;
  }

  /** Reaches only {@code schoolIds}. */
  public static AccessScope schools(Set<UUID> schoolIds) {
    return new AccessScope(false, false, schoolIds);
  }

  /** Whether this scope reaches any school at all. */
  public boolean isEmpty() {
    return !organizationWide && schoolIds.isEmpty();
  }
}
