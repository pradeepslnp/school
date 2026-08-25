package com.guardian.tenancy.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.tenancy.application.command.OrganizationLifecycleCommand;
import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationStatus;
import java.util.Map;
import org.springframework.stereotype.Service;

/**
 * Reactivates a suspended organization (feature TEN-004, {@code PERM-ORG-SUSPEND}, BR-TEN-006) —
 * the reverse of {@link SuspendOrganizationUseCase}; see that class's Javadoc for the bootstrap
 * and enforcement-location reasoning, which applies identically here.
 */
@Service
public class ReactivateOrganizationUseCase {

  private final OrganizationRepository organizationRepository;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public ReactivateOrganizationUseCase(
      OrganizationRepository organizationRepository,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.organizationRepository = organizationRepository;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public Organization execute(OrganizationLifecycleCommand command) {
    return tenantScoped.execute(command.id().asTenantId(), () -> applyReactivate(command));
  }

  private Organization applyReactivate(OrganizationLifecycleCommand command) {
    Organization existing =
        organizationRepository
            .findById(command.id())
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.ORGANIZATION_NOT_FOUND,
                        "BR-TEN-001",
                        Map.of("id", command.id().toString())));

    boolean wasAlreadyActive = existing.status() == OrganizationStatus.ACTIVE;

    Organization reactivated = organizationRepository.save(existing.reactivate());

    // Same reasoning as SuspendOrganizationUseCase: idempotent calls succeed, but only a real
    // transition is worth an audit entry.
    if (!wasAlreadyActive) {
      auditPort.record(
          AuditRecord.builder()
              .tenantId(reactivated.id().asTenantId())
              .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
              .action("ORGANIZATION_REACTIVATED")
              .subject("Organization", reactivated.id().value())
              .before(Map.of("status", existing.status().name()))
              .after(Map.of("status", reactivated.status().name()))
              .build());
    }

    return reactivated;
  }
}
