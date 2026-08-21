package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.AssignDutyCommand;
import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.domain.DutyAssignment;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Assigns a driver or attendant to a route's standing roster (feature STF-004).
 *
 * <p>Records intent only. Whether this person can actually start a trip on this route — a valid
 * licence, current verification (BR-STAFF-001/002) — is checked at trip start (BR-TRIP-004), not
 * here: an assignment can be made before every credential is in place, the same way a school
 * schedules a term before every textbook has arrived.
 */
@Service
@BusinessRule({"BR-STAFF-004", "BR-AUD-002"})
public class AssignDutyUseCase {

  private final DutyAssignmentRepository dutyAssignmentRepository;
  private final AuditPort auditPort;

  public AssignDutyUseCase(DutyAssignmentRepository dutyAssignmentRepository, AuditPort auditPort) {
    this.dutyAssignmentRepository = dutyAssignmentRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public DutyAssignment execute(AssignDutyCommand command) {
    TenantId tenantId = TenantContext.require();

    DutyAssignment assignment =
        DutyAssignment.create(
            tenantId, command.staffId(), command.routeId(), command.role(), command.direction());

    DutyAssignment saved = dutyAssignmentRepository.save(assignment);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("DUTY_ASSIGNED")
            .subject("DutyAssignment", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(DutyAssignment assignment) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("routeId", assignment.routeId().value());
    values.put("staffId", assignment.staffId().value());
    values.put("role", assignment.role().name());
    values.put("direction", assignment.direction().map(Enum::name).orElse(null));
    return values;
  }
}
