package com.guardian.tenancy.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.tenancy.application.port.SchoolRepository;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolId;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reads schools (feature TEN-002).
 *
 * <p>No explicit tenant filtering appears here: row-level security applies it to every query
 * (ADR-0001). A school in another organization is genuinely not found, which is why this throws
 * {@link ResourceNotFoundException} rather than a permission error — the resource does not exist as
 * far as this request is concerned (guardian-docs/04-api/API_STANDARDS.md).
 */
@Service
public class GetSchoolUseCase {

  private final SchoolRepository schoolRepository;

  public GetSchoolUseCase(SchoolRepository schoolRepository) {
    this.schoolRepository = schoolRepository;
  }

  @Transactional(readOnly = true)
  public School byId(SchoolId schoolId) {
    return schoolRepository
        .findById(schoolId)
        .orElseThrow(
            () ->
                new ResourceNotFoundException(
                    ErrorCode.SCHOOL_NOT_FOUND, "School", schoolId.value()));
  }

  @Transactional(readOnly = true)
  public List<School> activeByOrganization(OrganizationId organizationId) {
    return schoolRepository.findActiveByOrganization(organizationId);
  }
}
