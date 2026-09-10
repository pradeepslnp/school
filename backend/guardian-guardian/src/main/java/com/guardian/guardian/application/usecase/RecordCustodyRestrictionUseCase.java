package com.guardian.guardian.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.guardian.application.port.CustodyRestrictionRepository;
import com.guardian.guardian.domain.CustodyRestriction;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Records a custody restriction (feature GRD-006, screen A-14).
 *
 * <p>This is the operation that overrides an explicit right, so it is gated tightly and always
 * audited with its reason (BR-AUD-004). The effect is immediate: the next handover or visibility
 * check reads {@code is_active} directly, with no cache in between.
 *
 * <p>The domain type enforces the shape — exactly one subject, a non-blank reason, a sane window.
 * This use case adds only what needs the database: that a named guardian actually exists.
 */
@Service
public class RecordCustodyRestrictionUseCase {

  private final CustodyRestrictionRepository restrictions;
  private final AuditPort audit;

  public RecordCustodyRestrictionUseCase(
      CustodyRestrictionRepository restrictions, AuditPort audit) {
    this.restrictions = restrictions;
    this.audit = audit;
  }

  @Transactional
  @BusinessRule({"BR-GRD-008", "BR-HAND-006", "BR-AUD-004"})
  public CustodyRestriction execute(
      UUID studentId,
      UUID restrictedGuardianId,
      String restrictedPersonName,
      String type,
      String reason,
      Instant effectiveFrom,
      Instant effectiveUntil,
      UUID actorUserId,
      String actorRole) {

    boolean hasGuardian = restrictedGuardianId != null;
    boolean hasName = restrictedPersonName != null && !restrictedPersonName.isBlank();
    if (hasGuardian == hasName) {
      throw new BusinessRuleViolationException(
          ErrorCode.CUSTODY_RESTRICTION_SUBJECT_REQUIRED, "BR-GRD-008");
    }
    if (hasGuardian && !restrictions.guardianExists(restrictedGuardianId)) {
      throw new BusinessRuleViolationException(
          ErrorCode.CUSTODY_RESTRICTION_SUBJECT_REQUIRED,
          "BR-GRD-008",
          Map.of("restrictedGuardianId", restrictedGuardianId.toString()));
    }

    CustodyRestriction restriction =
        new CustodyRestriction(
            null,
            studentId,
            restrictedGuardianId,
            restrictedPersonName,
            parseType(type),
            reason,
            effectiveFrom == null ? Instant.now() : effectiveFrom,
            effectiveUntil,
            true);

    CustodyRestriction saved = restrictions.save(restriction, actorUserId);

    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("CUSTODY_RESTRICTION_RECORDED")
            .subject("CustodyRestriction", saved.id())
            .reason(saved.reason())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static CustodyRestriction.Type parseType(String type) {
    try {
      return CustodyRestriction.Type.valueOf(type == null ? "" : type.trim());
    } catch (IllegalArgumentException e) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT,
          "BR-GRD-008",
          Map.of("field", "restrictionType", "allowed", "NO_HANDOVER, NO_VISIBILITY, FULL"));
    }
  }

  private static Map<String, Object> describe(CustodyRestriction restriction) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("studentId", restriction.studentId().toString());
    values.put(
        "subject",
        restriction.restrictedGuardianId() != null
            ? "guardian:" + restriction.restrictedGuardianId()
            : "person:" + restriction.restrictedPersonName());
    values.put("type", restriction.type().name());
    values.put("effectiveFrom", restriction.effectiveFrom().toString());
    return values;
  }
}
