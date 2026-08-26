package com.guardian.tenancy.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.tenancy.application.port.PlatformOrganizationDirectory;
import com.guardian.tenancy.domain.Organization;
import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Service;

/**
 * Platform health at a glance (screen A-62, {@code PERM-PLATFORM-HEALTH-VIEW}), {@code
 * SUPER_ADMIN} only — the role check mirrors {@link ListOrganizationsUseCase}'s interim pattern
 * rather than the audited elevation path (BR-TEN-004 🔴, not yet built); see that class's Javadoc.
 *
 * <p><b>Placement.</b> This use case lives here, in {@code guardian-tenancy}, rather than in a
 * dedicated platform-operations module — none exists yet, and this reuses {@link
 * PlatformOrganizationDirectory}, the one cross-tenant read this codebase already has, instead of
 * inventing a second. Revisit alongside that port's own "interim" label if a real
 * platform-operations module is ever justified by more than this one screen.
 *
 * <h2>Why {@code databaseReachable} is best-effort, not a guarantee</h2>
 *
 * <p>This is not an infrastructure health check in the Actuator sense. By the time a request
 * reaches this use case, it has already passed authentication, tenant resolution, and permission
 * resolution — all of which touch the database too. A genuine full outage almost always surfaces
 * earlier, as a 500 from one of those, not as a graceful reading on this screen. What this class
 * catches is the narrower case where the platform-wide organization read itself fails — a timeout,
 * a lock, a bad query plan — while the rest of the request pipeline is otherwise healthy. Reported
 * honestly as "best effort" here and on the screen, rather than oversold as full monitoring this
 * platform does not have.
 */
@Service
public class GetPlatformHealthUseCase {

  private static final String PLATFORM_ROLE = "SUPER_ADMIN";

  private final PlatformOrganizationDirectory directory;

  public GetPlatformHealthUseCase(PlatformOrganizationDirectory directory) {
    this.directory = directory;
  }

  public PlatformHealthSnapshot execute(String actorRole) {
    if (!PLATFORM_ROLE.equals(actorRole)) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "platform-health", "*");
    }

    List<Organization> organizations;
    try {
      organizations = directory.listAll();
    } catch (RuntimeException e) {
      // Deliberately broad and deliberately swallowed: a health check that itself throws
      // defeats its own purpose. The caller sees "could not reach the database just now"
      // rather than a 500 with no useful signal.
      return new PlatformHealthSnapshot(false, 0, 0, 0, 0, Instant.now());
    }

    int active = 0;
    int suspended = 0;
    int closed = 0;
    for (Organization organization : organizations) {
      switch (organization.status()) {
        case ACTIVE -> active++;
        case SUSPENDED -> suspended++;
        case CLOSED -> closed++;
      }
    }

    return new PlatformHealthSnapshot(
        true, organizations.size(), active, suspended, closed, Instant.now());
  }
}
