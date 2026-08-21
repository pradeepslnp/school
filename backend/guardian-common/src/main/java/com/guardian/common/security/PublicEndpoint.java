package com.guardian.common.security;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks an endpoint as deliberately unauthenticated.
 *
 * <p>The annotation exists so that "no permission" is an explicit, reviewable decision rather than
 * an omission. Only login, OTP, password reset, and JWKS should carry it.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface PublicEndpoint {

  /** Why this endpoint is reachable without authentication. */
  String reason();
}
