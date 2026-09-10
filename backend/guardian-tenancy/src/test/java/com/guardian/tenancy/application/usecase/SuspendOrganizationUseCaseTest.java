package com.guardian.tenancy.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.tenancy.application.command.OrganizationLifecycleCommand;
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

/** Unit tests for the use case (TEN-004, BR-TEN-006). Ports are mocked; no Spring context. */
@ExtendWith(MockitoExtension.class)
class SuspendOrganizationUseCaseTest {

  private static final UUID ACTOR = UUID.randomUUID();
  private static final OrganizationId ORG_ID = OrganizationId.generate();

  @Mock private OrganizationRepository organizationRepository;
  @Mock private AuditPort auditPort;
  @Mock private TenantScopedTransaction tenantScoped;

  private SuspendOrganizationUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new SuspendOrganizationUseCase(organizationRepository, auditPort, tenantScoped);

    when(tenantScoped.execute(any(), any()))
        .thenAnswer(inv -> ((Supplier<?>) inv.getArgument(1)).get());
  }

  private static Organization organizationWithStatus(OrganizationStatus status) {
    return new Organization(
        ORG_ID,
        OrganizationCode.of("GREENWOOD"),
        "Greenwood Education Group",
        "IN",
        status,
        "contact@greenwood.example",
        null,
        0L);
  }

  private static OrganizationLifecycleCommand command() {
    return new OrganizationLifecycleCommand(ORG_ID, ACTOR, "SUPER_ADMIN");
  }

  @Test
  @DisplayName("bootstraps the transaction to the target organization's own id")
  void bootstrapsToTheTargetOrganization() {
    when(organizationRepository.findById(ORG_ID))
        .thenReturn(Optional.of(organizationWithStatus(OrganizationStatus.ACTIVE)));
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
  @DisplayName("suspends an active organization and records an audit entry")
  void suspendsActiveOrganization() {
    when(organizationRepository.findById(ORG_ID))
        .thenReturn(Optional.of(organizationWithStatus(OrganizationStatus.ACTIVE)));
    when(organizationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Organization result = useCase.execute(command());

    assertThat(result.status()).isEqualTo(OrganizationStatus.SUSPENDED);

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());
    AuditRecord record = captor.getValue();
    assertThat(record.action()).isEqualTo("ORGANIZATION_SUSPENDED");
    assertThat(record.beforeValues()).containsEntry("status", "ACTIVE");
    assertThat(record.afterValues()).containsEntry("status", "SUSPENDED");
  }

  @Test
  @DisplayName(
      "suspending an already-suspended organization is idempotent and writes no duplicate audit entry")
  void suspendingAlreadySuspendedIsIdempotent() {
    when(organizationRepository.findById(ORG_ID))
        .thenReturn(Optional.of(organizationWithStatus(OrganizationStatus.SUSPENDED)));
    when(organizationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Organization result = useCase.execute(command());

    assertThat(result.status()).isEqualTo(OrganizationStatus.SUSPENDED);
    verify(auditPort, never()).record(any());
  }

  @Test
  @DisplayName("refuses to suspend a closed organization")
  void refusesClosedOrganization() {
    when(organizationRepository.findById(ORG_ID))
        .thenReturn(Optional.of(organizationWithStatus(OrganizationStatus.CLOSED)));

    assertThatThrownBy(() -> useCase.execute(command())).isInstanceOf(IllegalStateException.class);
  }
}
