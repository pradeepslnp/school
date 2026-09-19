package com.guardian.guardian.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.DataConflictException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.guardian.application.port.GuardianAccountPort;
import com.guardian.guardian.application.port.GuardianAccountProvisioningPort;
import com.guardian.guardian.application.port.GuardianRepository;
import com.guardian.guardian.domain.Guardian;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Corrects a guardian's name, phone, or email (feature GRD-001, screen A-11).
 *
 * <p><strong>Correcting the phone moves the sign-in</strong> (BR-IAM-014, ADR-0019). A guardian
 * signs in by OTP against {@code users.phone}; the phone on the guardian record is a separate copy.
 * So a changed number is provisioned exactly as a new guardian's would be — the account already on
 * that number is reused, or one is created — the record is relinked to it, and the old account is
 * released: {@code GUARDIAN} removed, every session revoked, inactive if nothing else remains. The
 * old account is never edited in place, so anything done under it stays attributed to the number
 * that did it. A number that differs only in formatting resolves to the same account, and nothing
 * moves.
 *
 * <p>If the new number's account is already tied to a different guardian record, the correction is
 * refused with {@code 409 GUARDIAN_PHONE_IN_USE}: relinking would merge two people's access to
 * children, and only the office can tell which record is right.
 *
 * <p>All in one transaction, so a refusal rolls back the provisioning before it. The audit record
 * names the fields changed and whether the sign-in moved, never the values (BR-AUD-006).
 */
@Service
@BusinessRule({"BR-IAM-014", "BR-AUD-002"})
public class UpdateGuardianUseCase {

  private static final String RELEASE_REASON = "PHONE_CORRECTED";

  private final GuardianRepository guardians;
  private final GuardianAccountProvisioningPort accountProvisioning;
  private final GuardianAccountPort guardianAccounts;
  private final AuditPort auditPort;

  public UpdateGuardianUseCase(
      GuardianRepository guardians,
      GuardianAccountProvisioningPort accountProvisioning,
      GuardianAccountPort guardianAccounts,
      AuditPort auditPort) {
    this.guardians = guardians;
    this.accountProvisioning = accountProvisioning;
    this.guardianAccounts = guardianAccounts;
    this.auditPort = auditPort;
  }

  @Transactional
  public Guardian execute(
      UUID guardianId,
      String firstName,
      String lastName,
      String phone,
      String email,
      UUID actorUserId,
      String actorRole) {

    Guardian existing =
        guardians
            .findById(guardianId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.GUARDIAN_NOT_FOUND, "Guardian", guardianId));

    String cleanFirst = firstName.trim();
    String cleanLast = lastName.trim();
    String cleanPhone = phone.trim();
    String cleanEmail = email == null || email.isBlank() ? null : email.trim();

    UUID account = existing.userId();
    boolean signInMoved = false;
    if (!existing.phone().equals(cleanPhone)) {
      UUID newAccount =
          accountProvisioning.provision(cleanPhone, cleanFirst, cleanLast, actorUserId, actorRole);
      if (!newAccount.equals(existing.userId())) {
        if (guardians.existsByUserIdExcluding(newAccount, existing.id())) {
          throw new DataConflictException(ErrorCode.GUARDIAN_PHONE_IN_USE, Map.of());
        }
        account = newAccount;
        signInMoved = true;
      }
    }

    Guardian saved =
        guardians.updateGuardian(
            new Guardian(
                existing.id(),
                account,
                cleanFirst,
                cleanLast,
                cleanPhone,
                cleanEmail,
                existing.active()),
            actorUserId);

    String previousAccount = "UNCHANGED";
    if (signInMoved) {
      previousAccount =
          existing.userId() == null
              ? "NO_PREVIOUS_ACCOUNT"
              : guardianAccounts.release(existing.userId(), RELEASE_REASON, actorUserId, actorRole);
    }

    Map<String, Object> after = new LinkedHashMap<>();
    after.put("fieldsChanged", String.join(",", changedFields(existing, saved)));
    after.put("signInMoved", signInMoved);
    after.put("previousAccount", previousAccount);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("GUARDIAN_UPDATED")
            .subject("Guardian", saved.id())
            .after(after)
            .build());

    return saved;
  }

  /** Names only — the values are personal data and stay out of the audit trail. */
  private static List<String> changedFields(Guardian before, Guardian after) {
    List<String> changed = new ArrayList<>();
    if (!before.firstName().equals(after.firstName())) {
      changed.add("firstName");
    }
    if (!before.lastName().equals(after.lastName())) {
      changed.add("lastName");
    }
    if (!before.phone().equals(after.phone())) {
      changed.add("phone");
    }
    if (!Objects.equals(before.email(), after.email())) {
      changed.add("email");
    }
    return changed;
  }
}
