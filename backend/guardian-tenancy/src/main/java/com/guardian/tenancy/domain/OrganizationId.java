package com.guardian.tenancy.domain;

import com.guardian.common.tenant.TenantId;
import java.util.Objects;
import java.util.UUID;

/**
 * Identifies an organization — a school group.
 *
 * <p>The organization <em>is</em> the tenant (ADR-0001), so this converts directly to a {@link
 * TenantId}. The two types are kept distinct because they mean different things: this identifies a
 * business entity, {@code TenantId} identifies an isolation boundary. Most of the codebase should
 * only ever see the latter.
 */
public record OrganizationId(UUID value) {

  public OrganizationId {
    Objects.requireNonNull(value, "value");
  }

  public static OrganizationId of(UUID value) {
    return new OrganizationId(value);
  }

  public static OrganizationId generate() {
    return new OrganizationId(UUID.randomUUID());
  }

  public TenantId asTenantId() {
    return TenantId.of(value);
  }

  @Override
  public String toString() {
    return value.toString();
  }
}
