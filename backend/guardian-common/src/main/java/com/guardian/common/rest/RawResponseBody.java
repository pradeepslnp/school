package com.guardian.common.rest;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Exempts an endpoint from the standard {@code data} envelope
 * (guardian-docs/04-api/API_STANDARDS.md).
 *
 * <p>Almost nothing should carry this. The envelope is what lets every client parse every response
 * the same way, and an endpoint that opts out quietly is a client-side special case forever.
 *
 * <p>It exists for responses whose shape is fixed by a specification outside this platform — {@code
 * /.well-known/jwks.json} is defined by RFC 7517 and must be exactly a JWK Set, so wrapping it
 * would make it unreadable to every standard JWT library.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface RawResponseBody {

  /** Which specification fixes this response's shape. */
  String reason();
}
