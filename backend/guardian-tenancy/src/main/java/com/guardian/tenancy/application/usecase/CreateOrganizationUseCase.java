package com.guardian.tenancy.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.tenancy.application.command.CreateOrganizationCommand;
import com.guardian.tenancy.application.port.OrganizationCodeDirectory;
import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;

/**
 * Creates an organization — mints a new tenant (feature TEN-001).
 *
 * <p>Every other use case in this module runs inside a tenant the caller was already given by
 * {@code TenantContextFilter}. This one cannot: the organization being created does not exist yet,
 * so there is no context to be inside of, and the actor's own session tenant (a platform-operations
 * organization, for a {@code SUPER_ADMIN}) is not the tenant this row belongs to. {@code
 * organizations}' RLS policy checks {@code id = app.tenant_id} (V1__baseline_tenancy.sql) — the
 * write can only pass once context is set to the new organization's own generated id, which is
 * exactly what {@link TenantScopedTransaction} bootstraps: the same "resolve or mint a tenant, then
 * transact under it" shape {@code StaffLoginUseCase} and {@code VerifyOtpUseCase} use in
 * guardian-identity to establish a tenant before one is known.
 *
 * <p>For the same reason, uniqueness is checked through {@link OrganizationCodeDirectory} rather
 * than an ordinary repository read: an RLS-scoped {@code SELECT} under the actor's own tenant could
 * never see another organization's code (see that port's documentation).
 */
@Service
@BusinessRule({"BR-TEN-001", "BR-TEN-007", "BR-AUD-002"})
public class CreateOrganizationUseCase {

  private final OrganizationCodeDirectory codeDirectory;
  private final OrganizationRepository organizationRepository;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public CreateOrganizationUseCase(
      OrganizationCodeDirectory codeDirectory,
      OrganizationRepository organizationRepository,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.codeDirectory = codeDirectory;
    this.organizationRepository = organizationRepository;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  /**
   * @throws BusinessRuleViolationException {@code ORG_CODE_ALREADY_EXISTS} if another organization
   *     on the platform already uses this code (BR-TEN-007)
   */
  public Organization execute(CreateOrganizationCommand command) {
    // BR-TEN-007, checked platform-wide — see OrganizationCodeDirectory.
    if (codeDirectory.existsGlobally(command.code())) {
      throw new BusinessRuleViolationException(
          ErrorCode.ORG_CODE_ALREADY_EXISTS, "BR-TEN-007", Map.of("code", command.code().value()));
    }

    Organization organization =
        Organization.create(
            command.code(),
            command.name(),
            command.regionProfileCode(),
            command.contactEmail(),
            command.contactPhone());

    return tenantScoped.execute(
        organization.id().asTenantId(), () -> saveAndAudit(organization, command));
  }

  private Organization saveAndAudit(Organization organization, CreateOrganizationCommand command) {
    Organization saved = organizationRepository.save(organization);

    // BR-AUD-002: the audit write shares this transaction. If it fails, the organization is not
    // created — the platform refuses to mint a tenant it cannot also account for.
    auditPort.record(
        AuditRecord.builder()
            .tenantId(saved.id().asTenantId())
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("ORGANIZATION_CREATED")
            .subject("Organization", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(Organization organization) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("code", organization.code().value());
    values.put("name", organization.name());
    values.put("regionProfileCode", organization.regionProfileCode());
    values.put("status", organization.status().name());
    return values;
  }
}
