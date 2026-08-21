package com.guardian.tenancy.application.usecase;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationId;
import java.util.Map;
import org.springframework.stereotype.Service;

/** Reads a single organization (feature TEN-001). Ordinary tenant-scoped read (ADR-0001). */
@Service
public class GetOrganizationUseCase {

  private final OrganizationRepository organizationRepository;

  public GetOrganizationUseCase(OrganizationRepository organizationRepository) {
    this.organizationRepository = organizationRepository;
  }

  public Organization byId(OrganizationId id) {
    return organizationRepository
        .findById(id)
        .orElseThrow(
            () ->
                new BusinessRuleViolationException(
                    ErrorCode.ORGANIZATION_NOT_FOUND, "BR-TEN-001", Map.of("id", id.toString())));
  }
}
