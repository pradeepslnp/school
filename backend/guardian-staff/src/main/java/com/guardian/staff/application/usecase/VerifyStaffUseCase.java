package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.VerifyStaffCommand;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.TransportStaff;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Records a staff member as verified through {@code verifiedUntil} (feature STF-001,
 * PERM-STAFF-VERIFY).
 *
 * <p>{@code verifiedUntil} is required and validated by {@link TransportStaff#verify}, which throws
 * before an unbounded "verified forever" record can be persisted — the same rule the database
 * re-asserts with {@code ck_staff_verified_until}. This use case does not itself decide what
 * evidence counts as verification (a background-check integration, a manual document review); it
 * records the outcome and the date it lapses, keeping {@code verificationType} and {@code
 * referenceNumber} only in the audit trail since {@code transport_staff} has no columns for them.
 */
@Service
@BusinessRule({"BR-STAFF-002", "BR-AUD-002"})
public class VerifyStaffUseCase {

  private final TransportStaffRepository staffRepository;
  private final AuditPort auditPort;

  public VerifyStaffUseCase(TransportStaffRepository staffRepository, AuditPort auditPort) {
    this.staffRepository = staffRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public TransportStaff execute(VerifyStaffCommand command) {
    TenantId tenantId = TenantContext.require();

    TransportStaff existing =
        staffRepository
            .findById(command.staffId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "TransportStaff", command.staffId().value()));

    TransportStaff verified = staffRepository.save(existing.verify(command.verifiedUntil()));

    Map<String, Object> after = new LinkedHashMap<>();
    after.put("verificationStatus", verified.verificationStatus().name());
    after.put("verifiedUntil", command.verifiedUntil().toString());
    after.put("verificationType", command.verificationType());
    after.put("referenceNumber", command.referenceNumber());

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("TRANSPORT_STAFF_VERIFIED")
            .subject("TransportStaff", verified.id().value())
            .before(Map.of("verificationStatus", existing.verificationStatus().name()))
            .after(after)
            .build());

    return verified;
  }
}
