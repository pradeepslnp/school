package com.guardian.common.error;

import java.util.Map;

/**
 * The caller's organization is suspended (BR-TEN-006).
 *
 * <p>Raised only after authentication, at the point a permission is checked — never at login.
 * Login failures for an unknown email, a wrong password, and an inactive account are all
 * deliberately reported as the same {@link ErrorCode#AUTH_CREDENTIALS_INVALID} to avoid
 * disclosing which emails belong to real accounts (BR-IAM-001); a distinctly worded suspension
 * error at login would reopen that hole for suspended organizations specifically. Blocking here
 * instead — after the caller is already known to be who they say they are — closes the same
 * access gap without an enumeration surface.
 *
 * <p>Suspension "blocks all user access except platform operations" (BR-TEN-006). It does not
 * stop in-flight safety recording for a trip already started — the permission check that raises
 * this exception is expected to allow-list the trip/boarding/handover/SOS/incident/alert/
 * tracking/reconciliation permission families through rather than reaching this branch for them.
 */
public class OrganizationSuspendedException extends DomainException {

  public OrganizationSuspendedException(String organizationId) {
    super(ErrorCode.ORG_SUSPENDED, Map.of("organizationId", organizationId));
  }

  @Override
  public String businessRule() {
    return "BR-TEN-006";
  }
}
