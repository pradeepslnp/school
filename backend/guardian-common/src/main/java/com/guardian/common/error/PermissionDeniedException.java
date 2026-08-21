package com.guardian.common.error;

import java.util.Map;

/**
 * The caller does not hold the permission an endpoint declares (BR-IAM-002).
 *
 * <p>Distinct from {@link ErrorCode#AUTH_SCOPE_DENIED}, which answers the narrower question: the
 * caller holds the permission but not over <em>this</em> object. Holding {@code PERM-STUDENT-VIEW}
 * never implies access to a specific student.
 *
 * <p>The required permission is returned in the error context deliberately. It names a capability,
 * not a resource, so it discloses nothing about what exists — and without it a client sees only
 * "denied" with no way to tell an under-provisioned account from a genuine refusal.
 */
public class PermissionDeniedException extends DomainException {

  public PermissionDeniedException(String requiredPermission) {
    super(ErrorCode.AUTH_PERMISSION_DENIED, Map.of("requiredPermission", requiredPermission));
  }

  @Override
  public String businessRule() {
    return "BR-IAM-002";
  }
}
