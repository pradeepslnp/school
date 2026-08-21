package com.guardian.tenancy.application.port;

import com.guardian.tenancy.domain.Organization;
import java.util.List;

/**
 * Reads every organization on the platform, across every tenant.
 *
 * <p>Not an ordinary tenant-scoped read (contrast {@link OrganizationRepository}): RLS
 * (V1__baseline_tenancy.sql) restricts every request to {@code id = app.tenant_id}, so a normal
 * query can never see more than the caller's own organization row. This port exists for exactly one
 * caller — {@code ListOrganizationsUseCase} — and that use case, not the database, is what refuses
 * everyone except {@code SUPER_ADMIN}; see V12__organization_listing.sql for why the database-side
 * boundary is deliberately narrow (one function, unfiltered) rather than role-aware.
 *
 * <p><b>Interim.</b> The platform's real answer to cross-tenant reads is the audited elevation path
 * (BR-TEN-004 🔴, {@code PERM-PLATFORM-TENANT-ACCESS}), not yet built — see
 * V12__organization_listing.sql's full reasoning. This port should be retired in favour of that
 * path once it exists.
 */
public interface PlatformOrganizationDirectory {

  /** Every organization on the platform, ordered by name. */
  List<Organization> listAll();
}
