package com.guardian.staff.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.AddStaffCredentialCommand;
import com.guardian.staff.application.port.StaffCredentialRepository;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.StaffCredential;
import com.guardian.staff.domain.TransportStaff;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Attaches a licence or certification to a staff member (feature STF-002).
 *
 * <p>{@code credentialType} and {@code credentialClass} are validated only for presence here. Full
 * validation against the tenant's region profile (ADR-0007) is MOD-17 Configuration's
 * responsibility once that module exists; this use case does not yet call it, which is why
 * BR-STAFF-001's region-profile aspect remains listed in the traceability baseline as outstanding —
 * only the expiry and class-match mechanics are proven here.
 */
@Service
@BusinessRule("BR-STAFF-001")
public class AddStaffCredentialUseCase {

  private final TransportStaffRepository staffRepository;
  private final StaffCredentialRepository credentialRepository;
  private final AuditPort auditPort;

  public AddStaffCredentialUseCase(
      TransportStaffRepository staffRepository,
      StaffCredentialRepository credentialRepository,
      AuditPort auditPort) {
    this.staffRepository = staffRepository;
    this.credentialRepository = credentialRepository;
    this.auditPort = auditPort;
  }

  @Transactional
  public StaffCredential execute(AddStaffCredentialCommand command) {
    TenantId tenantId = TenantContext.require();

    TransportStaff staff =
        staffRepository
            .findById(command.staffId())
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STAFF_NOT_FOUND, "TransportStaff", command.staffId().value()));

    StaffCredential credential =
        StaffCredential.create(
            tenantId,
            staff.id(),
            command.credentialType(),
            command.credentialNumber(),
            command.credentialClass(),
            command.issuedOn(),
            command.expiresOn(),
            command.mandatory(),
            command.fileRef());

    StaffCredential saved = credentialRepository.save(credential);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("STAFF_CREDENTIAL_ADDED")
            .subject("StaffCredential", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(StaffCredential credential) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("staffId", credential.staffId().toString());
    values.put("credentialType", credential.credentialType());
    values.put("expiresOn", credential.expiresOn().toString());
    values.put("mandatory", credential.mandatory());
    return values;
  }
}
