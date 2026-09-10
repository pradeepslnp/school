package com.guardian.guardian.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.guardian.application.port.CustodyRestrictionRepository;
import com.guardian.guardian.domain.CustodyRestriction;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lifts a custody restriction (feature GRD-006, the {@code DELETE} on A-14).
 *
 * <p>Deactivation, never a delete: that a restriction was once in force — and when, and why — has
 * to stay answerable, because the situations these records describe end up in front of a court.
 * Immediate, like recording one: the handover check reads {@code is_active} at the moment of
 * collection.
 *
 * <p>The id in the path must belong to the student in the path. Without that check, a caller could
 * lift a restriction on any child by guessing an id while pointed at a student they can see.
 */
@Service
public class LiftCustodyRestrictionUseCase {

  private final CustodyRestrictionRepository restrictions;
  private final AuditPort audit;

  public LiftCustodyRestrictionUseCase(CustodyRestrictionRepository restrictions, AuditPort audit) {
    this.restrictions = restrictions;
    this.audit = audit;
  }

  @Transactional
  @BusinessRule({"BR-GRD-008", "BR-AUD-004"})
  public void execute(UUID studentId, UUID restrictionId, UUID actorUserId, String actorRole) {
    CustodyRestriction restriction =
        restrictions
            .findById(restrictionId)
            .filter(found -> found.studentId().equals(studentId))
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.CUSTODY_RESTRICTION_NOT_FOUND,
                        "CustodyRestriction",
                        restrictionId));

    restrictions.lift(restrictionId, actorUserId);

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("CUSTODY_RESTRICTION_LIFTED")
            .subject("CustodyRestriction", restrictionId)
            .before(Map.of("isActive", "true", "type", restriction.type().name()))
            .after(Map.of("isActive", "false"))
            .build());
  }
}
