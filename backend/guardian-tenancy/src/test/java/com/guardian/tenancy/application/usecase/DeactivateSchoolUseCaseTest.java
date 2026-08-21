package com.guardian.tenancy.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.tenancy.application.port.SchoolRepository;
import com.guardian.tenancy.domain.Coordinates;
import com.guardian.tenancy.domain.GeofenceRadius;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolCode;
import com.guardian.tenancy.domain.SchoolStatus;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/** Unit tests for the use case. Ports are mocked; no Spring context, no database. */
@ExtendWith(MockitoExtension.class)
class DeactivateSchoolUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final OrganizationId ORG = OrganizationId.generate();
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private SchoolRepository schoolRepository;
  @Mock private AuditPort auditPort;

  private DeactivateSchoolUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new DeactivateSchoolUseCase(schoolRepository, auditPort);
    TenantContext.set(TENANT);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static School activeSchool() {
    return School.create(
        TENANT,
        ORG,
        SchoolCode.of("GW-MAIN"),
        "Greenwood Main",
        ZoneId.of("Asia/Kolkata"),
        Coordinates.of("28.6129", "77.2290"),
        GeofenceRadius.ofMetres(150));
  }

  @Test
  @BusinessRule("BR-TEN-002")
  @DisplayName("refuses to deactivate an organization's last active school")
  void refusesToRemoveLastSchool() {
    School school = activeSchool();
    when(schoolRepository.findById(school.id())).thenReturn(Optional.of(school));
    when(schoolRepository.countActiveByOrganization(ORG)).thenReturn(1L);

    assertThatThrownBy(() -> useCase.execute(school.id(), ACTOR, "SCHOOL_ADMIN", "closing"))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.ORG_LAST_SCHOOL_CANNOT_BE_REMOVED);

    verify(schoolRepository, never()).save(any());
    verify(auditPort, never()).record(any());
  }

  @Test
  @BusinessRule("BR-TEN-002")
  @DisplayName("deactivates when other active schools remain")
  void deactivatesWhenOthersRemain() {
    School school = activeSchool();
    when(schoolRepository.findById(school.id())).thenReturn(Optional.of(school));
    when(schoolRepository.countActiveByOrganization(ORG)).thenReturn(3L);
    when(schoolRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    School result = useCase.execute(school.id(), ACTOR, "SCHOOL_ADMIN", "campus closed");

    assertThat(result.status()).isEqualTo(SchoolStatus.INACTIVE);
  }

  @Test
  @BusinessRule({"BR-AUD-002", "BR-AUD-003"})
  @DisplayName("records an audit entry carrying actor, role, reason, and before/after state")
  void writesAuditRecord() {
    School school = activeSchool();
    when(schoolRepository.findById(school.id())).thenReturn(Optional.of(school));
    when(schoolRepository.countActiveByOrganization(ORG)).thenReturn(2L);
    when(schoolRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(school.id(), ACTOR, "SCHOOL_ADMIN", "campus closed");

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());

    AuditRecord record = captor.getValue();
    assertThat(record.action()).isEqualTo("SCHOOL_DEACTIVATED");
    assertThat(record.actorId()).isEqualTo(ACTOR);
    assertThat(record.actorRole()).isEqualTo("SCHOOL_ADMIN");
    assertThat(record.reason()).isEqualTo("campus closed");
    assertThat(record.tenantId()).isEqualTo(TENANT);
    assertThat(record.beforeValues()).containsEntry("status", "ACTIVE");
    assertThat(record.afterValues()).containsEntry("status", "INACTIVE");
  }

  @Test
  @DisplayName("deactivating an already-inactive school is a no-op")
  void alreadyInactiveIsNoOp() {
    School inactive = activeSchool().deactivate();
    when(schoolRepository.findById(inactive.id())).thenReturn(Optional.of(inactive));

    School result = useCase.execute(inactive.id(), ACTOR, "SCHOOL_ADMIN", null);

    assertThat(result.status()).isEqualTo(SchoolStatus.INACTIVE);
    verify(schoolRepository, never()).save(any());
    verify(auditPort, never()).record(any());
  }
}
