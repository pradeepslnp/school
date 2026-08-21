package com.guardian.tenancy.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.tenancy.application.command.UpdateSchoolCommand;
import com.guardian.tenancy.application.port.SchoolRepository;
import com.guardian.tenancy.domain.Coordinates;
import com.guardian.tenancy.domain.GeofenceRadius;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.School;
import com.guardian.tenancy.domain.SchoolCode;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/** Unit tests for the use case. Ports are mocked; no Spring context, no database. */
@ExtendWith(MockitoExtension.class)
class UpdateSchoolUseCaseTest {

  private static final UUID ACTOR = UUID.randomUUID();
  private static final OrganizationId ORG = OrganizationId.generate();
  private static final TenantId TENANT = ORG.asTenantId();

  @Mock private SchoolRepository schoolRepository;
  @Mock private AuditPort auditPort;
  @Mock private TenantScopedTransaction tenantScoped;

  private UpdateSchoolUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new UpdateSchoolUseCase(schoolRepository, auditPort, tenantScoped);

    when(tenantScoped.execute(any(), any()))
        .thenAnswer(inv -> ((Supplier<?>) inv.getArgument(1)).get());
  }

  private static School existingSchool() {
    return School.create(
        TENANT,
        ORG,
        SchoolCode.of("GW-MAIN"),
        "Greenwood Main",
        ZoneId.of("Asia/Kolkata"),
        Coordinates.of("28.6129", "77.2290"),
        GeofenceRadius.ofMetres(150));
  }

  private UpdateSchoolCommand command(School school) {
    return new UpdateSchoolCommand(
        school.id(),
        ORG,
        "Greenwood Main Renamed",
        ZoneId.of("America/New_York"),
        Coordinates.of("29.0", "78.0"),
        GeofenceRadius.ofMetres(200),
        ACTOR,
        "SUPER_ADMIN");
  }

  @Test
  @DisplayName("bootstraps the transaction to the owning organization's tenant")
  void bootstrapsToTheOwningOrganization() {
    School school = existingSchool();
    when(schoolRepository.findById(school.id())).thenReturn(Optional.of(school));
    when(schoolRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(command(school));

    ArgumentCaptor<TenantId> tenantCaptor = ArgumentCaptor.forClass(TenantId.class);
    verify(tenantScoped).execute(tenantCaptor.capture(), any());
    assertThat(tenantCaptor.getValue()).isEqualTo(ORG.asTenantId());
  }

  @Test
  @DisplayName("a school that does not exist is refused")
  void missingSchoolIsRefused() {
    School school = existingSchool();
    when(schoolRepository.findById(school.id())).thenReturn(Optional.empty());

    assertThatThrownBy(() -> useCase.execute(command(school)))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.SCHOOL_NOT_FOUND);
  }

  @Test
  @DisplayName("saves the updated name, timezone, location, and geofence")
  void savesUpdatedFields() {
    School school = existingSchool();
    when(schoolRepository.findById(school.id())).thenReturn(Optional.of(school));
    when(schoolRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    School result = useCase.execute(command(school));

    assertThat(result.name()).isEqualTo("Greenwood Main Renamed");
    assertThat(result.timezone()).isEqualTo(ZoneId.of("America/New_York"));
    assertThat(result.geofenceRadius()).isEqualTo(GeofenceRadius.ofMetres(200));
    assertThat(result.code()).isEqualTo(SchoolCode.of("GW-MAIN"));
  }

  @Test
  @DisplayName("records an audit entry under the owning organization's tenant")
  void writesAuditRecord() {
    School school = existingSchool();
    when(schoolRepository.findById(school.id())).thenReturn(Optional.of(school));
    when(schoolRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(command(school));

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());

    AuditRecord record = captor.getValue();
    assertThat(record.action()).isEqualTo("SCHOOL_UPDATED");
    assertThat(record.tenantId()).isEqualTo(ORG.asTenantId());
    assertThat(record.beforeValues()).containsEntry("name", "Greenwood Main");
    assertThat(record.afterValues()).containsEntry("name", "Greenwood Main Renamed");
  }
}
