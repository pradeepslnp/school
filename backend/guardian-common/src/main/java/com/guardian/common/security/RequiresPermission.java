package com.guardian.common.security;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Declares the permission required to invoke an endpoint.
 *
 * <p>Access is deny-by-default (BR-IAM-002): an architecture test fails the build for any endpoint
 * annotated with neither this nor {@link PublicEndpoint}, so an unprotected endpoint cannot ship.
 *
 * <p>A companion test parses guardian-docs/01-product-discovery/PERMISSION_MATRIX.md and asserts
 * every value used here exists there — the code cannot drift from the matrix.
 *
 * <p>Holding the permission is necessary but not sufficient. Object-level scope must still be
 * checked ({@code OWN_CHILDREN}, {@code SCHOOL}, {@code TRIP}): holding {@code PERM-STUDENT-VIEW}
 * never implies access to a <em>specific</em> student.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface RequiresPermission {

  /** Permission code from the permission matrix — {@code "PERM-SCHOOL-VIEW"}. */
  String value();
}
