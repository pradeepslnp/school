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
import com.guardian.tenancy.application.command.UpdateOrganizationCommand;
import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationCode;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.OrganizationStatus;
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
class UpdateOrganizationUseCaseTest {

  private static final UUID ACTOR = UUID.randomUUID();
  private static final OrganizationId ORG_ID = OrganizationId.generate();

  @Mock private OrganizationRepository organizationRepository;
  @Mock private AuditPort auditPort;
  @Mock private TenantScopedTransaction tenantScoped;

  private UpdateOrganizationUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new UpdateOrganizationUseCase(organizationRepository, auditPort, tenantScoped);

    when(tenantScoped.execute(any(), any()))
        .thenAnswer(inv -> ((Supplier<?>) inv.getArgument(1)).get());
  }

  private static Organization existingOrganization() {
    return new Organization(
        ORG_ID,
        OrganizationCode.of("GREENWOOD"),
        "Greenwood Education Group",
        "IN",
        OrganizationStatus.ACTIVE,
        "old@greenwood.example",
        null,
        0L);
  }

  private static UpdateOrganizationCommand command() {
    return new UpdateOrganizationCommand(
        ORG_ID,
        "Greenwood Group Renamed",
        "US",
        "new@greenwood.example",
        "+15551234567",
        ACTOR,
        "SUPER_ADMIN");
  }

  @Test
  @DisplayName("bootstraps the transaction to the target organization's own id, not the actor's")
  void bootstrapsToTheTargetOrganization() {
    when(organizationRepository.findById(ORG_ID)).thenReturn(Optional.of(existingOrganization()));
    when(organizationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(command());

    ArgumentCaptor<TenantId> tenantCaptor = ArgumentCaptor.forClass(TenantId.class);
    verify(tenantScoped).execute(tenantCaptor.capture(), any());
    assertThat(tenantCaptor.getValue()).isEqualTo(ORG_ID.asTenantId());
  }

  @Test
  @DisplayName("an organization that does not exist is refused")
  void missingOrganizationIsRefused() {
    when(organizationRepository.findById(ORG_ID)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.ORGANIZATION_NOT_FOUND);
  }

  @Test
  @DisplayName("saves the updated fields and leaves code and status untouched")
  void savesUpdatedFields() {
    when(organizationRepository.findById(ORG_ID)).thenReturn(Optional.of(existingOrganization()));
    when(organizationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Organization result = useCase.execute(command());

    assertThat(result.name()).isEqualTo("Greenwood Group Renamed");
    assertThat(result.regionProfileCode()).isEqualTo("US");
    assertThat(result.contactEmail()).isEqualTo("new@greenwood.example");
    assertThat(result.code()).isEqualTo(OrganizationCode.of("GREENWOOD"));
  }

  @Test
  @DisplayName("records an audit entry carrying before and after values")
  void writesAuditRecord() {
    when(organizationRepository.findById(ORG_ID)).thenReturn(Optional.of(existingOrganization()));
    when(organizationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(command());

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());

    AuditRecord record = captor.getValue();
    assertThat(record.action()).isEqualTo("ORGANIZATION_UPDATED");
    assertThat(record.beforeValues()).containsEntry("name", "Greenwood Education Group");
    assertThat(record.afterValues()).containsEntry("name", "Greenwood Group Renamed");
  }
}
