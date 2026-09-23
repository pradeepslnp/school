package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.AssignDutyCommand;
import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.TransportStaff;
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
 *
 * <p><strong>One thing is checked here, and it is not a credential:</strong> the duty's role must
 * be what the staff member actually is. Rostering an attendant as the route's driver is not a
 * missing document that will arrive later — it is a wrong row, and leaving it to trip start means
 * the refusal lands on a driver at the kerb at 06:30 instead of on the office a week earlier, when
 * it could still be fixed. BR-STAFF-001's licence check only ever runs against the DRIVER duty, so
 * nothing downstream would have caught it either.
 */
@Service
@BusinessRule({"BR-STAFF-004", "BR-AUD-002"})
public class AssignDutyUseCase {

  private final DutyAssignmentRepository dutyAssignmentRepository;
  private final TransportStaffRepository transportStaffRepository;
  private final AuditPort auditPort;

  public AssignDutyUseCase(
      DutyAssignmentRepository dutyAssignmentRepository,
      TransportStaffRepository transportStaffRepository,
      AuditPort auditPort) {
    this.dutyAssignmentRepository = dutyAssignmentRepository;
    this.transportStaffRepository = transportStaffRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public DutyAssignment execute(AssignDutyCommand command) {
    TenantId tenantId = TenantContext.require();

    TransportStaff staff =
        transportStaffRepository
            .findById(command.staffId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "TransportStaff", command.staffId().value()));

    if (!staff.staffType().name().equals(command.role().name())) {
      throw new BusinessRuleViolationException(
          ErrorCode.STAFF_ROLE_MISMATCH,
          "BR-STAFF-001",
          Map.of(
              "staffType", staff.staffType().name(),
              "requestedRole", command.role().name()));
    }

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
