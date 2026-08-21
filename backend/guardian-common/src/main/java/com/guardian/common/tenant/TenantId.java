package com.guardian.common.tenant;

import java.util.Objects;
import java.util.UUID;

/**
 * The organization that owns a row.
 *
 * <p>Always the organization ID, never the school ID (ADR-0002). School-level scoping is
 * authorisation, layered above isolation — conflating the two is the commonest mistake in this
 * design. See guardian-docs/02-system-design/MULTI_TENANCY.md.
 */
public record TenantId(UUID value) {

  public TenantId {
    Objects.requireNonNull(value, "value");
  }

  public static TenantId of(UUID value) {
    return new TenantId(value);
  }

  public static TenantId fromString(String value) {
    return new TenantId(UUID.fromString(value));
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
