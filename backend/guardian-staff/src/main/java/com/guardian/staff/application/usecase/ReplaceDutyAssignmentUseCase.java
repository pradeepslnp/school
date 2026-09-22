package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.DutyAssignmentId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.TransportStaff;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Puts a different driver or attendant on a route's standing roster in place of the current one —
 * the one someone reaches for when the regular crew member has left, or is away long enough that
 * the roster itself should change (feature STF-004, screen A-25).
 *
 * <p><strong>This is the roster, not today's trip.</strong> A substitute for a single run is
 * recorded against that trip ({@code trip_staff}, BR-STAFF-006, STF-005) precisely so that one
 * absence does not rewrite who normally runs the route. That path needs MOD-08 and does not exist
 * yet; until it does, the roster change here is the only crew change the platform records.
 *
 * <p>Old off and new on in <strong>one transaction</strong>: a route must never be left with two
 * active crew members in the same role, nor with none because the second call failed. The
 * replacement inherits the role and direction of the assignment it replaces — changing who drives
 * and what they drive at the same time is two decisions, and this endpoint makes one.
 *
 * <p>A reason is required and recorded with both people, as every driver or attendant change on
 * this platform is (CLAUDE.md §5, BR-AUD-002).
 */
@Service
@BusinessRule({"BR-STAFF-004", "BR-IAM-008", "BR-AUD-002"})
public class ReplaceDutyAssignmentUseCase {

  private static final int REASON_MAX_LENGTH = 500;

  private final DutyAssignmentRepository dutyAssignmentRepository;
  private final TransportStaffRepository staffRepository;
  private final AuditPort auditPort;

  public ReplaceDutyAssignmentUseCase(
      DutyAssignmentRepository dutyAssignmentRepository,
      TransportStaffRepository staffRepository,
      AuditPort auditPort) {
    this.dutyAssignmentRepository = dutyAssignmentRepository;
    this.staffRepository = staffRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public DutyAssignment execute(
      DutyAssignmentId id, StaffId replacementId, String reason, UUID actorId, String actorRole) {
    TenantId tenantId = TenantContext.require();
    String trimmedReason = requireReason(reason);

    DutyAssignment current =
        dutyAssignmentRepository
            .findById(id)
            .filter(DutyAssignment::active)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "DutyAssignment", id.value()));

    if (current.staffId().equals(replacementId)) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE, "BR-STAFF-004", Map.of("field", "staffId"));
    }

    // BR-IAM-008: a deactivated staff member is off every future duty, so they cannot be given
    // one here either. Licence and verification are checked when a trip starts (BR-STAFF-001/002).
    TransportStaff replacement =
        staffRepository
            .findById(replacementId)
            .filter(TransportStaff::active)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "TransportStaff", replacementId.value()));

    dutyAssignmentRepository.save(current.deactivate());

    DutyAssignment assigned =
        dutyAssignmentRepository.save(
            DutyAssignment.create(
                tenantId,
                replacement.id(),
                current.routeId(),
                current.role(),
                current.direction().orElse(null)));

    Map<String, Object> before = new LinkedHashMap<>();
    before.put("dutyAssignmentId", current.id().value().toString());
    before.put("staffId", current.staffId().value().toString());

    Map<String, Object> after = new LinkedHashMap<>();
    after.put("dutyAssignmentId", assigned.id().value().toString());
    after.put("staffId", assigned.staffId().value().toString());
    after.put("routeId", assigned.routeId().value().toString());
    after.put("role", assigned.role().name());
    after.put("direction", assigned.direction().map(Enum::name).orElse("BOTH"));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("DUTY_ASSIGNMENT_REPLACED")
            .subject("DutyAssignment", assigned.id().value())
            .reason(trimmedReason)
            .before(before)
            .after(after)
            .build());

    return assigned;
  }

  private static String requireReason(String reason) {
    if (reason == null || reason.isBlank()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-AUD-002", Map.of("field", "reason"));
    }
    String trimmed = reason.trim();
    if (trimmed.length() > REASON_MAX_LENGTH) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE,
          "BR-AUD-002",
          Map.of("field", "reason", "maxLength", REASON_MAX_LENGTH));
    }
    return trimmed;
  }
}
