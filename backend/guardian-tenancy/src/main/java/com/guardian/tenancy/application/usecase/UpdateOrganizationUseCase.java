package com.guardian.tenancy.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.tenancy.application.command.UpdateOrganizationCommand;
import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;

/**
 * Edits an organization's own details (feature TEN-001, {@code PERM-ORG-EDIT}).
 *
 * <p>Bootstraps to the target organization's own id the same way {@link CreateOrganizationUseCase}
 * does, and for the same structural reason: the id in the URL is not necessarily the caller's own
 * session tenant — a {@code SUPER_ADMIN} editing an organization it does not belong to is exactly
 * the shape this endpoint exists for.
 *
 * <h2>What this does not yet enforce</h2>
 *
 * <p>Bootstrapping straight to the path id, rather than requiring the caller's own tenant to
 * already match it, is safe for {@code CreateOrganizationUseCase} because nothing existed to
 * violate before the write. Here it is not the same guarantee: an {@code ORG_ADMIN} — who also
 * holds {@code PERM-ORG-EDIT} per PERMISSION_MATRIX.md — could in principle reach another
 * organization's row this way. The platform's real answer to that is the audited elevation path
 * (BR-TEN-004 🔴, {@code PERM-PLATFORM-TENANT-ACCESS}), which is not built yet; per-request
 * permission and scope resolution is likewise a documented, tracked gap (see
 * traceability-baseline.txt, BR-IAM-001/004). This method is only as safe as that resolution is,
 * same as every other use case in this codebase today — it adds no new exposure, but it does not
 * close the existing one either. Revisit when platform-operations access lands.
 */
@Service
public class UpdateOrganizationUseCase {

  private final OrganizationRepository organizationRepository;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public UpdateOrganizationUseCase(
      OrganizationRepository organizationRepository,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.organizationRepository = organizationRepository;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public Organization execute(UpdateOrganizationCommand command) {
    return tenantScoped.execute(command.id().asTenantId(), () -> applyUpdate(command));
  }

  private Organization applyUpdate(UpdateOrganizationCommand command) {
    Organization existing =
        organizationRepository
            .findById(command.id())
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.ORGANIZATION_NOT_FOUND,
                        "BR-TEN-001",
                        Map.of("id", command.id().toString())));

    Map<String, Object> before = describe(existing);

    Organization updated =
        existing.update(
            command.name(),
            command.regionProfileCode(),
            command.contactEmail(),
            command.contactPhone());

    Organization saved = organizationRepository.save(updated);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(saved.id().asTenantId())
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("ORGANIZATION_UPDATED")
            .subject("Organization", saved.id().value())
            .before(before)
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(Organization organization) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("name", organization.name());
    values.put("regionProfileCode", organization.regionProfileCode());
    values.put("contactEmail", organization.contactEmail());
    values.put("contactPhone", organization.contactPhone());
    return values;
  }
}
