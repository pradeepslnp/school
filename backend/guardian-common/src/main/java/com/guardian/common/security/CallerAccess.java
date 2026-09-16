package com.guardian.common.security;

import java.util.Objects;
import java.util.Set;

/**
 * What the authenticated caller may do, and where: their resolved permissions and their scope.
 *
 * <p>Most endpoints need only {@link RequiresPermission} — one permission, checked before the
 * controller runs. A read that spans several kinds of record, each gated by its own permission (the
 * console's global search, ADR-0017), has to decide per kind instead, and needs the whole set.
 *
 * <p>Supplied to controllers by an argument resolver from the same per-request resolution the
 * permission interceptor performs, so the endpoint's gate and the per-kind decisions can never
 * disagree (BR-IAM-004). Nothing here is read from the request or from the token.
 */
public record CallerAccess(Set<String> permissions, AccessScope scope) {

  public CallerAccess {
    permissions = Set.copyOf(Objects.requireNonNull(permissions, "permissions"));
    Objects.requireNonNull(scope, "scope");
  }

  /** Whether the caller currently holds {@code permission}. */
  public boolean holds(String permission) {
    return permissions.contains(permission);
  }
}
