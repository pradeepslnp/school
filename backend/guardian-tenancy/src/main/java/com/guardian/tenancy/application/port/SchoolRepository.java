package com.guardian.tenancy.application.port;

import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolCode;
import com.guardian.tenancy.domain.SchoolId;
import java.util.List;
import java.util.Optional;

/**
 * Persistence for {@link School}, defined in the domain's language.
 *
 * <p>Declared here in the application layer and implemented in infrastructure, so the dependency
 * points inward (ENGINEERING_PRINCIPLES.md §4). Method names describe intent — {@code
 * findActiveByOrganization}, not {@code findByOrgIdAndIsActiveTrue}, which would leak the ORM into
 * the domain's vocabulary.
 *
 * <p>Every method here is implicitly tenant-scoped: row-level security applies the {@code
 * tenant_id} predicate to every query (ADR-0001). A caller cannot ask for another tenant's schools,
 * and a forgotten filter returns zero rows rather than another organization's children.
 */
public interface SchoolRepository {

  Optional<School> findById(SchoolId id);

  Optional<School> findByCode(OrganizationId organizationId, SchoolCode code);

  List<School> findActiveByOrganization(OrganizationId organizationId);

  boolean existsByCode(OrganizationId organizationId, SchoolCode code);

  /** Counts active schools, used to enforce BR-TEN-002 (an organization keeps at least one). */
  long countActiveByOrganization(OrganizationId organizationId);

  School save(School school);
}
