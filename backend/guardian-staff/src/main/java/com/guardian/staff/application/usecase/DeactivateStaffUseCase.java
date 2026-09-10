package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.application.port.StaffSessionRevocationPort;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.TransportStaff;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Deactivates a staff member (features STF-001, IAM-008).
 *
 * <p>Soft deactivation only — no delete path exists. Trip history and audit records reference
 * staff, and they outlive a person's active tenure (BR-AUD-001). Idempotent: deactivating an
 * already-inactive record returns it unchanged rather than erroring.
 *
 * <p>BR-IAM-008, in one transaction: the record is marked inactive, <strong>every session the
 * linked login holds is revoked</strong> (a dismissed driver must not keep access to children's
 * locations for even the ≤15 minutes an access token would otherwise last), and <strong>every
 * standing duty assignment is cleared</strong> so the next roster does not put them on a vehicle. A
 * record created before the account-linking backfill may have no {@code userId} yet — there is then
 * no session to revoke, and only the duty half runs.
 */
@Service
@BusinessRule("BR-IAM-008")
public class DeactivateStaffUseCase {

  private final TransportStaffRepository staffRepository;
  private final DutyAssignmentRepository dutyAssignments;
  private final StaffSessionRevocationPort sessionRevocation;
  private final AuditPort auditPort;

  public DeactivateStaffUseCase(
      TransportStaffRepository staffRepository,
      DutyAssignmentRepository dutyAssignments,
      StaffSessionRevocationPort sessionRevocation,
      AuditPort auditPort) {
    this.staffRepository = staffRepository;
    this.dutyAssignments = dutyAssignments;
    this.sessionRevocation = sessionRevocation;
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

    int sessionsRevoked = existing.userId().map(sessionRevocation::revokeAllSessions).orElse(0);

    List<DutyAssignment> standing = dutyAssignments.findActiveByStaff(staffId);
    for (DutyAssignment assignment : standing) {
      dutyAssignments.save(assignment.deactivate());
    }

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("TRANSPORT_STAFF_DEACTIVATED")
            .subject("TransportStaff", deactivated.id().value())
            .reason(reason)
            .before(Map.of("active", true))
            .after(
                Map.of(
                    "active",
                    false,
                    "sessionsRevoked",
                    sessionsRevoked,
                    "dutyAssignmentsRemoved",
                    standing.size()))
            .build());

    return deactivated;
  }
}
