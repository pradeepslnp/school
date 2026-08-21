package com.guardian.tenancy.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.tenancy.application.command.CreateSchoolCommand;
import com.guardian.tenancy.application.port.SchoolRepository;
import com.guardian.tenancy.domain.School;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Creates a school (feature TEN-002).
 *
 * <p>One class, one operation. Constructor injection only, all dependencies final
 * (ENGINEERING_PRINCIPLES.md §5).
 */
@Service
@BusinessRule({"BR-TEN-003", "BR-TEN-007", "BR-AUD-002"})
public class CreateSchoolUseCase {

  private final SchoolRepository schoolRepository;
  private final AuditPort auditPort;

  public CreateSchoolUseCase(SchoolRepository schoolRepository, AuditPort auditPort) {
    this.schoolRepository = schoolRepository;
    this.auditPort = auditPort;
  }

  /**
   * @throws BusinessRuleViolationException if the code is already used within the organization
   *     (BR-TEN-007)
   */
  @Transactional
  public School execute(CreateSchoolCommand command) {
    TenantId tenantId = TenantContext.require();

    // BR-TEN-007: school codes are unique within their organization.
    if (schoolRepository.existsByCode(command.organizationId(), command.code())) {
      throw new BusinessRuleViolationException(
          ErrorCode.SCHOOL_CODE_ALREADY_EXISTS,
          "BR-TEN-007",
          Map.of("code", command.code().value()));
    }

    School school =
        School.create(
            tenantId,
            command.organizationId(),
            command.code(),
            command.name(),
            command.timezone(),
            command.location(),
            command.geofenceRadius());

    School saved = schoolRepository.save(school);

    // BR-AUD-002: the audit write shares this transaction. If it fails, the school is not
    // created — the platform refuses an operation rather than performing it unrecorded.
    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("SCHOOL_CREATED")
            .subject("School", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(School school) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("code", school.code().value());
    values.put("name", school.name());
    values.put("organizationId", school.organizationId().toString());
    values.put("timezone", school.timezone().getId());
    values.put("status", school.status().name());
    return values;
  }
}
