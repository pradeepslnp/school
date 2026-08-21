package com.guardian.staff.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.TransportStaff;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Deactivates a staff member (feature STF-001, IAM-008).
 *
 * <p>Soft deactivation only — no delete path exists. Trip history and audit records reference
 * staff, and they outlive a person's active tenure (BR-AUD-001). Idempotent: deactivating an
 * already-inactive record returns it unchanged rather than erroring.
 */
@Service
public class DeactivateStaffUseCase {

  private final TransportStaffRepository staffRepository;
  private final AuditPort auditPort;

  public DeactivateStaffUseCase(TransportStaffRepository staffRepository, AuditPort auditPort) {
    this.staffRepository = staffRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public TransportStaff execute(StaffId staffId, UUID actorId, String actorRole, String reason) {
    TenantId tenantId = TenantContext.require();

    TransportStaff existing =
        staffRepository
            .findById(staffId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "TransportStaff", staffId.value()));

    if (!existing.active()) {
      return existing;
    }

    TransportStaff deactivated = staffRepository.save(existing.deactivate());

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("TRANSPORT_STAFF_DEACTIVATED")
            .subject("TransportStaff", deactivated.id().value())
            .reason(reason)
            .before(Map.of("active", true))
            .after(Map.of("active", false))
            .build());

    return deactivated;
  }
}
