package com.guardian.common;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Cites the business rule a test proves, or a method enforces.
 *
 * <p>This is what makes traceability machine-checkable. CI parses
 * guardian-docs/01-product-discovery/BUSINESS_RULES.md, collects every annotation, and
 * <strong>fails the build for any rule with no test</strong>. Safety-critical (🔴) rules require
 * coverage at two levels — the decision and its enforcement.
 *
 * <p>A rule that is documented but untested is worse than an undocumented one: it creates
 * confidence that nothing supports.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
// FIELD is included because ArchUnit rules are declared as static final fields, and those
// rules carry some of the strongest guarantees in the codebase — they must be traceable to
// the business rule they enforce like any other test.
@Target({ElementType.METHOD, ElementType.TYPE, ElementType.FIELD})
public @interface BusinessRule {

  /** One or more rule IDs — {@code "BR-TEN-002"}. */
  String[] value();
}
