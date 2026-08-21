package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.DataConflictException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.CreateTransportStaffCommand;
import com.guardian.staff.application.port.StaffAccountProvisioningPort;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.TransportStaff;
import com.guardian.staff.domain.UserId;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Registers a driver or attendant, pending verification (feature STF-001) — and, in the same
 * transaction, provisions the sign-in they need to actually use the driver app. Before this, a
 * newly created record left {@code user_id} null "until the person's account is activated" (see
 * {@link TransportStaff#userId()}'s documentation) and nothing in the platform ever performed that
 * activation outside of seed data. This closes that gap rather than leaving driver-app access as a
 * manual, undocumented follow-up step.
 *
 * <p>One class, two operations rather than one, because a login is not optional scaffolding — see
 * {@link StaffAccountProvisioningPort}'s own documentation for why provisioning it lives behind a
 * port instead of a second call this module makes directly. Constructor injection only, all
 * dependencies final (guardian-docs/ENGINEERING_PRINCIPLES.md §5).
 *
 * <p>{@code employee_code} uniqueness within a school (MOD-05-06-fleet-staff.md) is enforced by the
 * database's unique constraint; {@link TransportStaffRepository#existsByEmployeeCode} checks it
 * pre-flight so a duplicate is reported as {@code STAFF_EMPLOYEE_CODE_EXISTS} rather than the
 * caller seeing the constraint violation surface as a generic failure. A race between two
 * concurrent creations still falls back to the constraint itself — this check narrows the window,
 * it does not replace the guarantee. Unlike a vehicle's registration number, this is not cited as a
 * business-rule check: it is a data-integrity constraint, not a documented BR.
 */
@Service
@BusinessRule("BR-AUD-002")
public class CreateTransportStaffUseCase {

  private final TransportStaffRepository staffRepository;
  private final StaffAccountProvisioningPort accountProvisioning;
  private final AuditPort auditPort;

  public CreateTransportStaffUseCase(
      TransportStaffRepository staffRepository,
      StaffAccountProvisioningPort accountProvisioning,
      AuditPort auditPort) {
    this.staffRepository = staffRepository;
    this.accountProvisioning = accountProvisioning;
    this.auditPort = auditPort;
  }

  @Transactional
  public TransportStaff execute(CreateTransportStaffCommand command) {
    TenantId tenantId = TenantContext.require();

    if (command.employeeCode() != null
        && !command.employeeCode().isBlank()
        && staffRepository.existsByEmployeeCode(command.schoolId(), command.employeeCode(), null)) {
      throw new DataConflictException(
          ErrorCode.STAFF_EMPLOYEE_CODE_EXISTS, Map.of("employeeCode", command.employeeCode()));
    }

    TransportStaff staff =
        TransportStaff.create(
            tenantId,
            command.schoolId(),
            command.staffType(),
            command.employeeCode(),
            command.firstName(),
            command.lastName(),
            command.phone(),
            command.vendorName());

    TransportStaff saved = staffRepository.save(staff);

    // Provisioned before the audit write, and in the same transaction as the staff record
    // itself: a driver this platform believes it created but cannot actually sign in as is a
    // worse state than refusing the creation outright, so a provisioning failure rolls both
    // back rather than leaving a half-registered record for someone to notice later.
    UserId userId =
        accountProvisioning.provision(
            saved.staffType(),
            saved.phone(),
            saved.firstName(),
            saved.lastName(),
            command.actorId(),
            command.actorRole());
    TransportStaff linked = staffRepository.save(saved.withUserId(userId));

    // BR-AUD-002: the audit write shares this transaction. If it fails, none of the above is
    // kept either — the platform refuses an operation rather than performing it unrecorded.
    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("TRANSPORT_STAFF_CREATED")
            .subject("TransportStaff", linked.id().value())
            .after(describe(linked))
            .build());

    return linked;
  }

  private static Map<String, Object> describe(TransportStaff staff) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("staffType", staff.staffType().name());
    values.put("employeeCode", staff.employeeCode().orElse(null));
    values.put("verificationStatus", staff.verificationStatus().name());
    return values;
  }
}
