package com.guardian.tenancy.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.tenancy.application.command.UpdateSchoolCommand;
import com.guardian.tenancy.application.port.SchoolRepository;
import com.guardian.tenancy.domain.School;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;

/**
 * Edits a school's own details (feature TEN-002, {@code PERM-SCHOOL-EDIT}).
 *
 * <p>Bootstrapped to {@code organizationId}'s own tenant via {@link TenantScopedTransaction}, the
 * same shape {@link UpdateOrganizationUseCase} uses and for the same reason — see that class's
 * documentation, including the note on what per-request scope enforcement this does not yet
 * provide.
 *
 * <p>{@code assertBelongsTo} still runs even though the tenant was already established from the
 * same {@code organizationId}: it is what turns "this school row does not belong to that
 * organization" into {@code SCHOOL_CANNOT_CHANGE_ORGANIZATION} rather than a row that RLS made
 * invisible and was reported as not found.
 */
@Service
@BusinessRule("BR-TEN-003")
public class UpdateSchoolUseCase {

  private final SchoolRepository schoolRepository;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public UpdateSchoolUseCase(
      SchoolRepository schoolRepository,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.schoolRepository = schoolRepository;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public School execute(UpdateSchoolCommand command) {
    return tenantScoped.execute(command.organizationId().asTenantId(), () -> applyUpdate(command));
  }

  private School applyUpdate(UpdateSchoolCommand command) {
    School existing =
        schoolRepository
            .findById(command.id())
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.SCHOOL_NOT_FOUND,
                        "BR-TEN-002",
                        Map.of("id", command.id().toString())));

    existing.assertBelongsTo(command.organizationId());

    Map<String, Object> before = describe(existing);

    School updated =
        existing
            .rename(command.name())
            .reschedule(command.timezone())
            .relocate(command.location(), command.geofenceRadius());

    School saved = schoolRepository.save(updated);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(command.organizationId().asTenantId())
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("SCHOOL_UPDATED")
            .subject("School", saved.id().value())
            .before(before)
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(School school) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("name", school.name());
    values.put("timezone", school.timezone().getId());
    values.put("latitude", school.location().latitude());
    values.put("longitude", school.location().longitude());
    values.put("geofenceRadiusM", school.geofenceRadius().metres());
    return values;
  }
}
