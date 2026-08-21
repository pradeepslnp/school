package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.DutyAssignmentId;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Removes a standing crew assignment (feature STF-004, {@code DELETE /duty-assignments/{id}}). */
@Service
@BusinessRule({"BR-STAFF-004", "BR-AUD-002"})
public class RemoveDutyAssignmentUseCase {

  private final DutyAssignmentRepository dutyAssignmentRepository;
  private final AuditPort auditPort;

  public RemoveDutyAssignmentUseCase(
      DutyAssignmentRepository dutyAssignmentRepository, AuditPort auditPort) {
    this.dutyAssignmentRepository = dutyAssignmentRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public void execute(DutyAssignmentId id, UUID actorId, String actorRole) {
    TenantId tenantId = TenantContext.require();

    DutyAssignment assignment =
        dutyAssignmentRepository
            .findById(id)
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.STAFF_NOT_FOUND,
                        "BR-STAFF-004",
                        Map.of("dutyAssignmentId", id.toString())));

    dutyAssignmentRepository.save(assignment.deactivate());

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("DUTY_ASSIGNMENT_REMOVED")
            .subject("DutyAssignment", assignment.id().value())
            .after(Map.of("routeId", assignment.routeId().value()))
            .build());
  }
}
