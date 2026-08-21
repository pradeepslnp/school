package com.guardian.guardian.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.guardian.application.port.PickupPersonRepository;
import com.guardian.guardian.domain.PickupPerson;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Nominates an adult to collect a child — feature GRD-004, screen P-07.
 *
 * <p>Two rules, both of which exist because this operation grants someone the right to take a child
 * away from a bus:
 *
 * <ul>
 *   <li><strong>Only a guardian holding {@code can_authorise_handover} may nominate</strong>
 *       (BR-GRD-006 🔴). {@code PERM-PICKUP-PERSON-MANAGE} is necessary and not sufficient: the
 *       right lives on the specific relationship, so a guardian may nominate for one child and not
 *       another.
 *   <li><strong>The window must not already be over.</strong> A nomination created already-expired
 *       is either a mistake or an attempt to leave something dormant on the list.
 * </ul>
 *
 * <p>The nomination is audited, and NTF-ADM-04 notifies <em>all</em> guardians holding the handover
 * right, so one guardian cannot quietly authorise someone the others would object to. That
 * notification is raised by MOD-12 from the audit event rather than called synchronously from here.
 */
@Service
public class NominatePickupPersonUseCase {

  private final PickupPersonRepository pickupPersons;
  private final AuditPort audit;

  public NominatePickupPersonUseCase(PickupPersonRepository pickupPersons, AuditPort audit) {
    this.pickupPersons = pickupPersons;
    this.audit = audit;
  }

  @Transactional
  @BusinessRule({"BR-GRD-005", "BR-GRD-006"})
  public PickupPerson execute(
      UUID studentId,
      String fullName,
      String phone,
      String relationshipNote,
      Instant validFrom,
      Instant validUntil,
      UUID actorUserId,
      String actorRole) {

    UUID nominatingGuardianId =
        pickupPersons
            .nominatingGuardianIdFor(actorUserId, studentId)
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.GUARDIAN_NOT_AUTHORISED_TO_NOMINATE,
                        "BR-GRD-006",
                        Map.of("studentId", studentId.toString())));

    if (!validUntil.isAfter(Instant.now())) {
      throw new BusinessRuleViolationException(
          ErrorCode.PICKUP_PERSON_OUTSIDE_VALIDITY,
          "BR-GRD-005",
          Map.of("validUntil", validUntil.toString()));
    }

    // The constructor enforces the window's shape; this use case enforces who may create one.
    PickupPerson nomination =
        new PickupPerson(
            null,
            studentId,
            nominatingGuardianId,
            fullName.trim(),
            phone.trim(),
            blankToNull(relationshipNote),
            validFrom,
            validUntil,
            true);

    PickupPerson saved = pickupPersons.save(nomination, actorUserId);

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("PICKUP_PERSON_NOMINATED")
            .subject("AuthorisedPickupPerson", saved.id())
            .after(
                Map.of(
                    "studentId", studentId.toString(),
                    "fullName", saved.fullName(),
                    "validFrom", saved.validFrom().toString(),
                    "validUntil", saved.validUntil().toString()))
            .build());

    return saved;
  }

  private static String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }
}
