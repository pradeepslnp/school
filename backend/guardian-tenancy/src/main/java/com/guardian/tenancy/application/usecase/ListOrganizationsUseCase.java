package com.guardian.tenancy.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.tenancy.application.port.PlatformOrganizationDirectory;
import com.guardian.tenancy.domain.Organization;
import java.util.List;
import org.springframework.stereotype.Service;

/**
 * Lists every organization on the platform (feature TEN-001), for the Organizations screen (A-40).
 *
 * <p>{@code PERM-ORG-VIEW} alone is not a sufficient gate here — {@code ORG_ADMIN} holds it too
 * (PERMISSION_MATRIX.md), but this use case answers with rows from every tenant, not just the
 * caller's own. Until the audited elevation path exists (BR-TEN-004 🔴, {@code
 * PERM-PLATFORM-TENANT-ACCESS}), the role itself is checked directly: only {@code SUPER_ADMIN} may
 * call this. See {@link PlatformOrganizationDirectory} and V12__organization_listing.sql for the
 * full reasoning and the interim label on this whole path.
 */
@Service
public class ListOrganizationsUseCase {

  private static final String PLATFORM_ROLE = "SUPER_ADMIN";

  private final PlatformOrganizationDirectory directory;

  public ListOrganizationsUseCase(PlatformOrganizationDirectory directory) {
    this.directory = directory;
  }

  /**
   * @throws ResourceNotFoundException {@code AUTH_SCOPE_DENIED} if {@code actorRole} is not {@code
   *     SUPER_ADMIN} — the same code used elsewhere in this platform for "permission held, resource
   *     out of scope" (ERROR_CATALOG.md)
   */
  public List<Organization> execute(String actorRole) {
    if (!PLATFORM_ROLE.equals(actorRole)) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "organization", "*");
    }
    return directory.listAll();
  }
}
