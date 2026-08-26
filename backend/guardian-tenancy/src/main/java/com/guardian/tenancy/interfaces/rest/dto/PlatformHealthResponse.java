package com.guardian.tenancy.interfaces.rest.dto;

import com.guardian.tenancy.application.usecase.PlatformHealthSnapshot;
import java.time.Instant;

/** Wire representation of {@link PlatformHealthSnapshot} — the Platform health screen (A-62). */
public record PlatformHealthResponse(
    boolean databaseReachable,
    int totalOrganizations,
    int activeOrganizations,
    int suspendedOrganizations,
    int closedOrganizations,
    Instant checkedAt) {

  public static PlatformHealthResponse from(PlatformHealthSnapshot snapshot) {
    return new PlatformHealthResponse(
        snapshot.databaseReachable(),
        snapshot.totalOrganizations(),
        snapshot.activeOrganizations(),
        snapshot.suspendedOrganizations(),
        snapshot.closedOrganizations(),
        snapshot.checkedAt());
  }
}
