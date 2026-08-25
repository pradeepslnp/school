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
 * Suspends an organization (feature TEN-004, {@code PERM-ORG-SUSPEND}, BR-TEN-006).
 *
 * <p>Bootstraps to the target organization's own id, same as {@link UpdateOrganizationUseCase}
 * and for the same reason: {@code PERM-ORG-SUSPEND} is a platform-level permission held only by
 * {@code SUPER_ADMIN} (PERMISSION_MATRIX.md), and a platform operator suspending an organization
 * it does not itself belong to is exactly the shape this endpoint exists for.
 *
 * <p>This use case only flips the status and records the audit trail. It does not by itself stop
 * or allow any request — that enforcement lives in {@code PermissionEnforcementInterceptor},
 * which checks every subsequent request's target organization against this status. Suspending an
 * organization takes effect on the caller's very next request, not this one.
 */
@Service
public class SuspendOrganizationUseCase {

  private final OrganizationRepository organizationRepository;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public SuspendOrganizationUseCase(
      OrganizationRepository organizationRepository,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.organizationRepository = organizationRepository;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public Organization execute(OrganizationLifecycleCommand command) {
    return tenantScoped.execute(command.id().asTenantId(), () -> applySuspend(command));
  }

  private Organization applySuspend(OrganizationLifecycleCommand command) {
    Organization existing =
        organizationRepository
            .findById(command.id())
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.ORGANIZATION_NOT_FOUND,
                        "BR-TEN-001",
                        Map.of("id", command.id().toString())));

    boolean wasAlreadySuspended = existing.status() == OrganizationStatus.SUSPENDED;

    Organization suspended = organizationRepository.save(existing.suspend());

    // Idempotent calls still succeed (Organization.suspend()'s contract), but only the
    // transition itself is worth an audit entry — repeating it on an already-suspended
    // organization would otherwise write a misleading trail of duplicate "suspended" events
    // for one decision.
    if (!wasAlreadySuspended) {
      auditPort.record(
          AuditRecord.builder()
              .tenantId(suspended.id().asTenantId())
              .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
              .action("ORGANIZATION_SUSPENDED")
              .subject("Organization", suspended.id().value())
              .before(Map.of("status", existing.status().name()))
              .after(Map.of("status", suspended.status().name()))
              .build());
    }

    return suspended;
  }
}
