package com.guardian.tenancy.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.tenancy.application.port.SchoolRepository;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolId;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Deactivates a school (feature TEN-002).
 *
 * <p>Soft deactivation only — no delete path exists. Safety records reference schools, and they
 * outlive the school's operational life (BR-STU-005, BR-AUD-001).
 */
@Service
@BusinessRule({"BR-TEN-002", "BR-AUD-002"})
public class DeactivateSchoolUseCase {

  private final SchoolRepository schoolRepository;
  private final AuditPort auditPort;

  public DeactivateSchoolUseCase(SchoolRepository schoolRepository, AuditPort auditPort) {
    this.schoolRepository = schoolRepository;
    this.auditPort = auditPort;
  }

  /**
   * @throws BusinessRuleViolationException if this is the organization's last active school
   *     (BR-TEN-002)
   */
  @Transactional
  public School execute(SchoolId schoolId, UUID actorId, String actorRole, String reason) {
    TenantId tenantId = TenantContext.require();

    School school =
        schoolRepository
            .findById(schoolId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.SCHOOL_NOT_FOUND, "School", schoolId.value()));

    if (!school.isActive()) {
      return school;
    }

    // BR-TEN-002: an organization always contains at least one school. Deactivating the
    // last one would leave students and vehicles attached to nothing operable.
    long remaining = schoolRepository.countActiveByOrganization(school.organizationId());
    if (remaining <= 1) {
      throw new BusinessRuleViolationException(
          ErrorCode.ORG_LAST_SCHOOL_CANNOT_BE_REMOVED,
          "BR-TEN-002",
          Map.of("organizationId", school.organizationId().toString()));
    }

    School deactivated = schoolRepository.save(school.deactivate());

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("SCHOOL_DEACTIVATED")
            .subject("School", deactivated.id().value())
            .reason(reason)
            .before(Map.of("status", school.status().name()))
            .after(Map.of("status", deactivated.status().name()))
            .build());

    return deactivated;
  }
}
