package com.guardian.guardian.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.guardian.application.port.PickupPersonRepository;
import com.guardian.guardian.domain.PickupPerson;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Revokes a nomination — feature GRD-005.
 *
 * <p>Immediate (BR-GRD-007): the row is marked inactive in this transaction, and the handover check
 * reads {@code is_active} at the moment of collection. There is no cache and no scheduled expiry
 * sweep between the two, which is what makes "immediate" true rather than aspirational.
 *
 * <p>The record stays. Who was authorised to collect a child in March has to remain answerable
 * after an incident, and a deleted row answers nothing.
 */
@Service
public class RevokePickupPersonUseCase {

  private final PickupPersonRepository pickupPersons;
  private final AuditPort audit;

  public RevokePickupPersonUseCase(PickupPersonRepository pickupPersons, AuditPort audit) {
    this.pickupPersons = pickupPersons;
    this.audit = audit;
  }

  @Transactional
  @BusinessRule("BR-GRD-007")
  public void execute(UUID studentId, UUID pickupPersonId, UUID actorUserId, String actorRole) {
    PickupPerson person =
        pickupPersons
            .findById(pickupPersonId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.AUTH_SCOPE_DENIED, "pickupPerson", pickupPersonId));

    // The id in the path must belong to the student in the path. Without this, a guardian of
    // child A could revoke a nomination on child B by guessing an id — the URL would look
    // legitimate and the scope check on A would pass.
    if (!person.studentId().equals(studentId)) {
      throw new ResourceNotFoundException(
          ErrorCode.AUTH_SCOPE_DENIED, "pickupPerson", pickupPersonId);
    }

    if (pickupPersons.nominatingGuardianIdFor(actorUserId, studentId).isEmpty()) {
      throw new BusinessRuleViolationException(
          ErrorCode.GUARDIAN_NOT_AUTHORISED_TO_NOMINATE,
          "BR-GRD-006",
          Map.of("studentId", studentId.toString()));
    }

    pickupPersons.revoke(pickupPersonId, actorUserId);

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("PICKUP_PERSON_REVOKED")
            .subject("AuthorisedPickupPerson", pickupPersonId)
            .before(Map.of("isActive", "true", "fullName", person.fullName()))
            .after(Map.of("isActive", "false"))
            .build());
  }
}
