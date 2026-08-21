package com.guardian.tenancy;

import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.AbstractIntegrationTest;
import com.guardian.common.BusinessRule;
import com.guardian.common.tenant.TenantId;
import com.guardian.tenancy.application.port.SchoolRepository;
import com.guardian.tenancy.domain.Coordinates;
import com.guardian.tenancy.domain.GeofenceRadius;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolCode;
import java.time.ZoneId;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * Tenant isolation for the tenancy module's repository.
 *
 * <p><strong>Every module must have an equivalent test</strong>
 * (guardian-docs/07-testing/TEST_STRATEGY.md). This is the pattern to copy.
 *
 * <p>The property being proved is precise: a query that omits a tenant filter returns <em>zero
 * rows</em>, not another organization's data. That is what makes ADR-0001's "structural, not
 * conventional" claim true rather than aspirational — and note that none of the repository methods
 * under test contain a tenant predicate at all.
 */
class SchoolTenantIsolationIT extends AbstractIntegrationTest {

  @Autowired private SchoolRepository schoolRepository;

  private School schoolFor(TenantId tenant, OrganizationId organization, String code) {
    return School.create(
        tenant,
        organization,
        SchoolCode.of(code),
        "Campus " + code,
        ZoneId.of("Asia/Kolkata"),
        Coordinates.of("28.6129", "77.2290"),
        GeofenceRadius.ofMetres(150));
  }

  private OrganizationId orgA() {
    return OrganizationId.of(ORGANIZATION_A);
  }

  private OrganizationId orgB() {
    return OrganizationId.of(ORGANIZATION_B);
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("data written under one tenant is invisible to another")
  void dataIsInvisibleAcrossTenants() {
    School saved =
        inTenant(TENANT_A, () -> schoolRepository.save(schoolFor(TENANT_A, orgA(), "A-1")));

    List<School> seenByB =
        inTenant(TENANT_B, () -> schoolRepository.findActiveByOrganization(orgA()));
    assertThat(seenByB).isEmpty();

    // ...and it is still there for its owner, so the empty result above is isolation
    // rather than a write that silently failed.
    assertThat(inTenant(TENANT_A, () -> schoolRepository.findById(saved.id()))).isPresent();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("a direct lookup by ID across tenants finds nothing")
  void findByIdIsIsolated() {
    School saved =
        inTenant(TENANT_A, () -> schoolRepository.save(schoolFor(TENANT_A, orgA(), "A-2")));

    assertThat(inTenant(TENANT_B, () -> schoolRepository.findById(saved.id()))).isEmpty();
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("existence checks do not leak another tenant's data")
  void existenceChecksAreIsolated() {
    inTenant(TENANT_A, () -> schoolRepository.save(schoolFor(TENANT_A, orgA(), "SHARED")));

    // If this saw across tenants, B would be blocked from a code that is free for them —
    // and would thereby learn that A uses it.
    boolean existsForB =
        inTenant(TENANT_B, () -> schoolRepository.existsByCode(orgA(), SchoolCode.of("SHARED")));

    assertThat(existsForB).isFalse();
  }

  @Test
  @BusinessRule({"BR-TEN-004", "BR-TEN-002"})
  @DisplayName("counts are tenant-scoped, so the last-school rule cannot be evaded")
  void countsAreIsolated() {
    inTenant(TENANT_A, () -> schoolRepository.save(schoolFor(TENANT_A, orgA(), "A-3")));
    inTenant(TENANT_A, () -> schoolRepository.save(schoolFor(TENANT_A, orgA(), "A-4")));
    inTenant(TENANT_B, () -> schoolRepository.save(schoolFor(TENANT_B, orgB(), "B-1")));

    assertThat(inTenant(TENANT_A, () -> schoolRepository.countActiveByOrganization(orgA())))
        .isEqualTo(2L);
    assertThat(inTenant(TENANT_B, () -> schoolRepository.countActiveByOrganization(orgB())))
        .isEqualTo(1L);
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("with no tenant context, the repository returns nothing")
  void unsetContextSeesNothing() {
    inTenant(TENANT_A, () -> schoolRepository.save(schoolFor(TENANT_A, orgA(), "A-5")));

    assertThat(withoutTenantContext(() -> schoolRepository.findActiveByOrganization(orgA())))
        .isEmpty();
  }
}
