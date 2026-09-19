package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.security.AccessScope;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.application.port.StaffAccountPort;
import com.guardian.staff.application.port.StaffCredentialRepository;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.TransportStaff;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Permanently removes a driver or attendant record that was entered by mistake (feature STF-007,
 * BR-STAFF-007, ADR-0019). Someone who actually worked is never discarded — they are deactivated
 * ({@link DeactivateStaffUseCase}, BR-IAM-008).
 *
 * <p><strong>Two refusals, both answered {@code 422 STAFF_HAS_SAFETY_RECORDS}:</strong>
 *
 * <ol>
 *   <li>The linked sign-in account has signed in. From then on events may have been recorded under
 *       it, and a staff record they can be traced back to must remain.
 *   <li>The database refuses the delete. Every table recording what staff did references {@code
 *       transport_staff} {@code ON DELETE RESTRICT}; once this record's own credentials and duty
 *       assignments are gone, any remaining reference is history. The foreign keys are the list —
 *       nothing here enumerates tables, so a table added later is protected by its own declaration.
 * </ol>
 *
 * <p>Everything happens in one transaction: a refusal at the last step rolls back the credential
 * and duty deletions before it, so a refused discard changes nothing.
 *
 * <p>The sign-in account is released, not deleted (BR-IAM-014): its role and sessions go, and it
 * becomes inactive if it holds nothing else. The audit record keeps identifiers and counts, never
 * the person's name or phone (BR-AUD-006).
 */
@Service
@BusinessRule({"BR-STAFF-007", "BR-AUD-002"})
public class DiscardTransportStaffUseCase {

  private static final int REASON_MAX_LENGTH = 500;

  private final TransportStaffRepository staffRepository;
  private final StaffCredentialRepository credentials;
  private final DutyAssignmentRepository dutyAssignments;
  private final StaffAccountPort staffAccounts;
  private final AuditPort auditPort;

  public DiscardTransportStaffUseCase(
      TransportStaffRepository staffRepository,
      StaffCredentialRepository credentials,
      DutyAssignmentRepository dutyAssignments,
      StaffAccountPort staffAccounts,
      AuditPort auditPort) {
    this.staffRepository = staffRepository;
    this.credentials = credentials;
    this.dutyAssignments = dutyAssignments;
    this.staffAccounts = staffAccounts;
    this.auditPort = auditPort;
  }

  @Transactional
  public void execute(
      StaffId staffId, String reason, AccessScope scope, UUID actorId, String actorRole) {
    TenantId tenantId = TenantContext.require();
    String trimmedReason = requireReason(reason);

    TransportStaff staff =
        staffRepository
            .findById(staffId)
            .filter(found -> inScope(scope, found))
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "TransportStaff", staffId.value()));

    if (staff.userId().map(staffAccounts::hasSignedIn).orElse(false)) {
      throw refused();
    }

    int credentialsRemoved = credentials.deleteAllForStaff(staff.id());
    int dutyAssignmentsRemoved = dutyAssignments.deleteAllForStaff(staff.id());

    if (!staffRepository.discard(staff.id())) {
      throw refused();
    }

    String accountOutcome =
        staff
            .userId()
            .map(
                userId ->
                    staffAccounts.release(
                        userId, staff.staffType(), "STAFF_DISCARDED", actorId, actorRole))
            .orElse("NO_ACCOUNT");

    Map<String, Object> before = new LinkedHashMap<>();
    before.put("staffType", staff.staffType().name());
    before.put("schoolId", staff.schoolId().value().toString());
    before.put("employeeCode", staff.employeeCode().orElse(""));
    before.put("active", staff.active());

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("TRANSPORT_STAFF_DISCARDED")
            .subject("TransportStaff", staff.id().value())
            .reason(trimmedReason)
            .before(before)
            .after(
                Map.of(
                    "credentialsRemoved", credentialsRemoved,
                    "dutyAssignmentsRemoved", dutyAssignmentsRemoved,
                    "signInAccount", accountOutcome))
            .build());
  }

  /** A school-scoped caller discards only within their own schools; outside them, not found. */
  private static boolean inScope(AccessScope scope, TransportStaff staff) {
    return scope.organizationWide() || scope.schoolIds().contains(staff.schoolId().value());
  }

  private static String requireReason(String reason) {
    if (reason == null || reason.isBlank()) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING, "BR-STAFF-007", Map.of("field", "reason"));
    }
    String trimmed = reason.trim();
    if (trimmed.length() > REASON_MAX_LENGTH) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE,
          "BR-STAFF-007",
          Map.of("field", "reason", "maxLength", REASON_MAX_LENGTH));
    }
    return trimmed;
  }

  private static BusinessRuleViolationException refused() {
    return new BusinessRuleViolationException(ErrorCode.STAFF_HAS_SAFETY_RECORDS, "BR-STAFF-007");
  }
}
