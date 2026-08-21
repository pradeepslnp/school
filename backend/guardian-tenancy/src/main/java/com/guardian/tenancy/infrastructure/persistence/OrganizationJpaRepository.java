package com.guardian.tenancy.infrastructure.persistence;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository. Package-private — callers use {@link
 * com.guardian.tenancy.application.port.OrganizationRepository} via {@link
 * OrganizationRepositoryAdapter}.
 *
 * <p>No query here filters on tenant. For {@code findById}/{@code save}, row-level security applies
 * the {@code id = app.tenant_id} predicate to every statement (ADR-0001) — an application filter
 * would suggest isolation depends on remembering it. The one read that must see across tenants
 * ({@code org_code_exists}) does not go through this repository at all; see {@link
 * JdbcOrganizationCodeDirectory}.
 */
interface OrganizationJpaRepository extends JpaRepository<OrganizationEntity, UUID> {}
