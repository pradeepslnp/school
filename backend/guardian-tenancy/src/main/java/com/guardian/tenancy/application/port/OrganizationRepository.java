package com.guardian.tenancy.application.port;

import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationId;
import java.util.Optional;

/**
 * Persistence for {@link Organization}, defined in the domain's language.
 *
 * <p>Unlike {@link SchoolRepository}, a caller of {@code save} here is not already inside the
 * tenant it is writing — {@link com.guardian.tenancy.application.usecase.CreateOrganizationUseCase}
 * calls it from inside a transaction bootstrapped to the *new* organization's own generated id,
 * because that organization did not exist a moment earlier for any context to be inside of. {@code
 * findById} is ordinary and tenant-scoped like every other read in this module (ADR-0001) — it is
 * used once an organization's own context is already established, never to search across tenants.
 */
public interface OrganizationRepository {

  Optional<Organization> findById(OrganizationId id);

  Organization save(Organization organization);
}
