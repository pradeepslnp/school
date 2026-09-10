package com.guardian.common.security;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks an endpoint that requires authentication but no permission from the matrix, because it acts
 * only on the caller's <em>own</em> identity — listing their sessions, ending one, logging out.
 *
 * <p>Distinct from {@link PublicEndpoint} (unauthenticated — how a session is obtained) and from
 * {@link RequiresPermission} (an authorised action on someone or something else). Acting on your
 * own session is neither: the {@code CurrentActor} argument resolver already answers {@code 401}
 * when no principal is present, and there is nothing further to authorise — a person may always end
 * their own session. An endpoint that touches another user's sessions is a {@link
 * RequiresPermission} {@code PERM-SESSION-REVOKE} action instead, and belongs on a different path.
 *
 * <p>Like {@link PublicEndpoint}, this exists so "no permission" is an explicit, reviewable
 * decision the deny-by-default architecture test (BR-IAM-002) accepts, rather than an omission.
 * Keep the set that carries it small: self-service session management is its only current use.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface SelfServiceEndpoint {

  /** Why this endpoint needs authentication but no matrix permission. */
  String reason();
}
