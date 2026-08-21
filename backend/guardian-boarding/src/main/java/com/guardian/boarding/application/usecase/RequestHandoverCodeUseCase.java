package com.guardian.boarding.application.usecase;

import com.guardian.boarding.application.port.HandoverCodeRepository;
import com.guardian.boarding.domain.HandoverCode;
import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Issues a handover verification code — feature P-12, the "show this to the attendant" screen.
 *
 * <p>One rule, and it exists because this operation hands out a credential that releases a child:
 *
 * <ul>
 *   <li><strong>Only a guardian holding {@code can_authorise_handover} may request a code</strong>
 *       (BR-GRD-006 🔴). {@code PERM-HANDOVER-CODE-REQUEST} says a guardian may request handover
 *       codes; it does not say for <em>which child</em> — the same asymmetry {@link
 *       com.guardian.boarding.application.port.HandoverCodeRepository} documents for MOD-04's
 *       pickup-person nomination.
 * </ul>
 *
 * <p>What this deliberately does not do: verify the code, release the student, or write a handover
 * record (BR-HAND-001 through BR-HAND-007). Those require the driver/attendant app's write path,
 * which this codebase does not yet have — see the module's build file.
 */
@Service
public class RequestHandoverCodeUseCase {

  /**
   * Matches PARENT_APP.md's P-12 mockup ("code expires 3:35 PM") — long enough to walk from the
   * school gate to the vehicle, short enough that a screenshot is useless a few minutes later.
   */
  private static final Duration CODE_LIFETIME = Duration.ofMinutes(10);

  private final HandoverCodeRepository codes;
  private final AuditPort audit;
  private final SecureRandom random;

  // A single constructor, deliberately — every other use case in this codebase has exactly
  // one, which is what lets Spring's implicit constructor injection apply with no
  // @Autowired annotation needed. A second, package-private constructor for injecting a
  // seeded SecureRandom in tests is a plausible-looking addition that buys an untested
  // convenience at the cost of that guarantee; not worth it for one class.
  public RequestHandoverCodeUseCase(HandoverCodeRepository codes, AuditPort audit) {
    this.codes = codes;
    this.audit = audit;
    this.random = new SecureRandom();
  }

  @Transactional
  @BusinessRule({"BR-GRD-006", "BR-HAND-002"})
  public HandoverCode execute(UUID studentId, UUID actorUserId, String actorRole) {
    UUID guardianId =
        codes
            .authorisingGuardianIdFor(actorUserId, studentId)
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.GUARDIAN_NOT_AUTHORISED_FOR_HANDOVER,
                        "BR-GRD-006",
                        Map.of("studentId", studentId.toString())));

    Instant issuedAt = Instant.now();
    HandoverCode requested =
        new HandoverCode(
            null, studentId, guardianId, generateCode(), issuedAt, issuedAt.plus(CODE_LIFETIME));

    HandoverCode saved = codes.issue(requested, actorUserId);

    // Same transaction as the write (BR-AUD-002): a credential that releases a child is
    // exactly the kind of event whose audit record cannot be allowed to silently not happen.
    // The code itself is never written to the audit trail — the record establishes *that* a
    // code was requested and by whom, not what the code was.
    audit.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("HANDOVER_CODE_REQUESTED")
            .subject("HandoverVerificationCode", saved.id())
            .after(
                Map.of(
                    "studentId", studentId.toString(),
                    "expiresAt", saved.expiresAt().toString()))
            .build());

    return saved;
  }

  private String generateCode() {
    return String.format("%06d", random.nextInt(1_000_000));
  }
}
