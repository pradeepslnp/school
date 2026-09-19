package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.DataConflictException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.UpdateTransportStaffCommand;
import com.guardian.staff.application.port.StaffAccountPort;
import com.guardian.staff.application.port.StaffAccountProvisioningPort;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.TransportStaff;
import com.guardian.staff.domain.UserId;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
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
 *
 * <p><strong>Correcting the phone moves the sign-in</strong> (BR-IAM-014, ADR-0019). {@code phone}
 * here is only the roster copy; OTP sign-in resolves {@code users.phone}. So a changed number is
 * provisioned exactly as a new record's would be, the record is relinked to that account, and the
 * old account is released — role and every session gone, inactive if it holds nothing else. The old
 * account is never edited in place: whatever the wrong number's holder did stays attributed to it.
 * A number that differs only in formatting resolves to the same account, and nothing moves.
 */
@Service
@BusinessRule("BR-IAM-014")
public class UpdateTransportStaffUseCase {

  private static final String RELEASE_REASON = "PHONE_CORRECTED";

  private final TransportStaffRepository staffRepository;
  private final StaffAccountProvisioningPort accountProvisioning;
  private final StaffAccountPort staffAccounts;
  private final AuditPort auditPort;

  public UpdateTransportStaffUseCase(
      TransportStaffRepository staffRepository,
      StaffAccountProvisioningPort accountProvisioning,
      StaffAccountPort staffAccounts,
      AuditPort auditPort) {
    this.staffRepository = staffRepository;
    this.accountProvisioning = accountProvisioning;
    this.staffAccounts = staffAccounts;
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

    Optional<UserId> previousAccount = existing.userId();
    boolean signInMoved = false;
    if (!existing.phone().equals(updated.phone())) {
      UserId newAccount =
          accountProvisioning.provision(
              updated.staffType(),
              updated.phone(),
              updated.firstName(),
              updated.lastName(),
              command.actorId(),
              command.actorRole());
      signInMoved = !previousAccount.map(newAccount::equals).orElse(false);
      if (signInMoved) {
        updated = updated.withUserId(newAccount);
      }
    }

    TransportStaff saved = staffRepository.save(updated);

    String previousAccountOutcome = "UNCHANGED";
    if (signInMoved) {
      previousAccountOutcome =
          previousAccount
              .map(
                  account ->
                      staffAccounts.release(
                          account,
                          existing.staffType(),
                          RELEASE_REASON,
                          command.actorId(),
                          command.actorRole()))
              .orElse("NO_PREVIOUS_ACCOUNT");
    }

    // Names and phone are PII (CODING_STANDARDS_BACKEND.md) — the audit record notes that
    // contact details changed without echoing the values themselves.
    Map<String, Object> after = new LinkedHashMap<>();
    after.put("fieldsChanged", "firstName,lastName,phone,employeeCode,vendorName");
    after.put("signInMoved", signInMoved);
    after.put("previousAccount", previousAccountOutcome);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("TRANSPORT_STAFF_UPDATED")
            .subject("TransportStaff", saved.id().value())
            .after(after)
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
