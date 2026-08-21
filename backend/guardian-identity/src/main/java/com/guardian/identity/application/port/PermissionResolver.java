package com.guardian.identity.application.port;

import com.guardian.identity.domain.UserId;
import java.util.Set;

/**
 * Resolves the permissions a user currently holds.
 *
 * <p>Tenant-scoped implicitly: row-level security applies the {@code tenant_id} predicate to every
 * statement (ADR-0001), so a user's grants in another tenant are not merely filtered out — they are
 * not visible to the query at all.
 *
 * <p>Read at the moment of asking, never cached and never carried in the access token (BR-IAM-004,
 * ADR-0006). A role removed from a user takes effect on their next request rather than whenever
 * their token happens to expire — for a staff member who has just been deactivated, that is the
 * difference between "immediately" and "up to fifteen minutes of continued access to children's
 * locations". Caching the result here would reintroduce exactly the staleness the design rejects.
 */
public interface PermissionResolver {

  /** Permission codes from PERMISSION_MATRIX.md, union of every role the user holds. */
  Set<String> resolve(UserId userId);
}
