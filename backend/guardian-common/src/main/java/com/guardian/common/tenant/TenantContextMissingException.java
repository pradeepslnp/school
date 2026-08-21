package com.guardian.common.tenant;

import com.guardian.common.error.DomainException;
import com.guardian.common.error.ErrorCode;

/**
 * No tenant context was established for an operation that requires one.
 *
 * <p>This is a coding defect, not a client error — some path reached the application layer without
 * passing through the tenant filter, or a scheduled job forgot to set context per tenant.
 *
 * <p>Note that the database does not depend on this exception for safety: with no context set, the
 * RLS predicate compares against NULL and yields zero rows
 * (guardian-docs/03-database/RLS_POLICIES.md). The failure mode is "sees nothing", never "sees
 * everything". This exception exists to surface the bug loudly rather than let it masquerade as an
 * empty result.
 */
public class TenantContextMissingException extends DomainException {

  public TenantContextMissingException() {
    super(ErrorCode.TENANT_CONTEXT_MISSING);
  }
}
