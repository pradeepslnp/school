package com.guardian.identity.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * The reach of one of a user's roles — <em>which</em> organization, school, or route, answering
 * what {@link RoleId} alone cannot (BR-IAM-006, PERMISSION_MATRIX.md "Permission alone is
 * insufficient").
 *
 * <p>No aggregate of its own, matching {@code roles}/{@code user_roles} (see {@link
 * com.guardian.identity.application.port.RoleProvisioningPort}'s documentation on why): this is a
 * plain value read and written as a row, never loaded into a larger object graph.
 *
 * <p>{@code refId} is null for {@code PLATFORM} and {@code ORG} — a {@code SUPER_ADMIN} oversees
 * every organization, and an {@code ORG_ADMIN}'s tenant already says which one. It is required for
 * {@code SCHOOL} and {@code ROUTE}, where the tenant alone does not say which one
 * (MOD-02-identity.md "user_scopes").
 */
public record UserScope(Level level, UUID refId) {

  public UserScope {
    Objects.requireNonNull(level, "level");
    if ((level == Level.PLATFORM || level == Level.ORG) && refId != null) {
      throw new IllegalArgumentException(level + " scope must not carry a refId");
    }
    if ((level == Level.SCHOOL || level == Level.ROUTE) && refId == null) {
      throw new IllegalArgumentException(level + " scope requires a refId");
    }
  }

  public static UserScope organization() {
    return new UserScope(Level.ORG, null);
  }

  public static UserScope school(UUID schoolId) {
    return new UserScope(Level.SCHOOL, Objects.requireNonNull(schoolId, "schoolId"));
  }

  /** Matches the wire values already sent by the platform's other scope-carrying surfaces. */
  public enum Level {
    PLATFORM,
    ORG,
    SCHOOL,
    ROUTE;

    public static Level fromStored(String value) {
      return Level.valueOf(value);
    }
  }
}
