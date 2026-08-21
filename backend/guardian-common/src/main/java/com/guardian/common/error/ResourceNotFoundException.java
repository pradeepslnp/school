package com.guardian.common.error;

import java.util.Map;

/**
 * A resource does not exist, or is not visible to the caller at all.
 *
 * <p>Note the deliberate asymmetry in guardian-docs/04-api/API_STANDARDS.md: a resource outside the
 * caller's <em>scope</em> within their tenant returns 403, while a resource in another
 * <em>tenant</em> genuinely returns 404 — row-level security means it does not exist as far as this
 * request is concerned.
 */
public class ResourceNotFoundException extends DomainException {

  public ResourceNotFoundException(ErrorCode errorCode, String resourceType, Object identifier) {
    super(
        errorCode, Map.of("resourceType", resourceType, "identifier", String.valueOf(identifier)));
  }
}
