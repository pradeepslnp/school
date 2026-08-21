package com.guardian.staff.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.DataConflictException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.UpdateTransportStaffCommand;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.TransportStaff;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Updates a staff member's contact and record-keeping details — name, phone, employee code, and
 * vendor name (feature STF-001).
 *
 * <p>{@code staffType} and {@code verificationStatus} are not editable here. A type change would
 * silently invalidate credential-class checks already recorded against this staff member; a
 * verification change goes through {@link VerifyStaffUseCase} so the required {@code verifiedUntil}
 * date and the audit trail stay coupled (BR-STAFF-002).
 */
@Service
public class UpdateTransportStaffUseCase {

  private final TransportStaffRepository staffRepository;
  private final AuditPort auditPort;

  public UpdateTransportStaffUseCase(
      TransportStaffRepository staffRepository, AuditPort auditPort) {
    this.staffRepository = staffRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public TransportStaff execute(UpdateTransportStaffCommand command) {
    TenantId tenantId = TenantContext.require();

    TransportStaff existing =
        staffRepository
            .findById(command.staffId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "TransportStaff", command.staffId().value()));

    // Only checked when the code actually changes: re-saving a staff member's own unchanged
    // code must never conflict with itself (existsByEmployeeCode's excludingStaffId exists for
    // exactly this).
    boolean codeChanged =
        !Objects.equals(blankToNull(command.employeeCode()), existing.employeeCode().orElse(null));
    if (codeChanged
        && command.employeeCode() != null
        && !command.employeeCode().isBlank()
        && staffRepository.existsByEmployeeCode(
            existing.schoolId(), command.employeeCode(), existing.id())) {
      throw new DataConflictException(
          ErrorCode.STAFF_EMPLOYEE_CODE_EXISTS, Map.of("employeeCode", command.employeeCode()));
    }

    TransportStaff updated =
        existing.updateDetails(
            command.firstName(),
            command.lastName(),
            command.phone(),
            command.employeeCode(),
            command.vendorName());
    TransportStaff saved = staffRepository.save(updated);

    // Names and phone are PII (CODING_STANDARDS_BACKEND.md) — the audit record notes that
    // contact details changed without echoing the values themselves.
    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("TRANSPORT_STAFF_UPDATED")
            .subject("TransportStaff", saved.id().value())
            .after(Map.of("fieldsChanged", "firstName,lastName,phone,employeeCode,vendorName"))
            .build());

    return saved;
  }

  /** Matches {@code TransportStaff}'s own private treatment of an optional label. */
  private static String blankToNull(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }
}
