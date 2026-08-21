package com.guardian.tenancy.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.tenancy.application.command.CreateOrganizationCommand;
import com.guardian.tenancy.application.port.OrganizationCodeDirectory;
import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationCode;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Unit tests for the use case. Ports are mocked; no Spring context, no database.
 *
 * <p>{@link TenantScopedTransaction} is mocked to run its supplier immediately, matching {@code
 * StaffLoginUseCaseTest} — the boundary this use case actually owns is "check the code, then mint
 * and write the tenant", not the transaction manager itself.
 */
@ExtendWith(MockitoExtension.class)
class CreateOrganizationUseCaseTest {

  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private OrganizationCodeDirectory codeDirectory;
  @Mock private OrganizationRepository organizationRepository;
  @Mock private AuditPort auditPort;
  @Mock private TenantScopedTransaction tenantScoped;

  private CreateOrganizationUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase =
        new CreateOrganizationUseCase(
            codeDirectory, organizationRepository, auditPort, tenantScoped);

    // Runs the supplier immediately, standing in for a real transaction boundary — see the
    // class documentation. `lenient()` because the uniqueness-refusal test below never
    // reaches it and would otherwise fail strict stubbing on an unused stub.
    lenient()
        .when(tenantScoped.execute(any(), any()))
        .thenAnswer(inv -> ((Supplier<?>) inv.getArgument(1)).get());
  }

  private static CreateOrganizationCommand command() {
    return new CreateOrganizationCommand(
        OrganizationCode.of("GREENWOOD"),
        "Greenwood Education Group",
        "IN",
        "ops@greenwood.example",
        "+919876543210",
        ACTOR,
        "SUPER_ADMIN");
  }

  @Test
  @BusinessRule("BR-TEN-007")
  @DisplayName("a code already used anywhere on the platform is refused before any write")
  void duplicateCodeIsRefused() {
    when(codeDirectory.existsGlobally(OrganizationCode.of("GREENWOOD"))).thenReturn(true);

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.ORG_CODE_ALREADY_EXISTS);

    verify(organizationRepository, never()).save(any());
    verify(auditPort, never()).record(any());
  }

  @Test
  @BusinessRule("BR-TEN-001")
  @DisplayName("writes under the new organization's own generated id, not the actor's tenant")
  void savesUnderTheNewOrganizationsOwnTenant() {
    when(codeDirectory.existsGlobally(any())).thenReturn(false);
    when(organizationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Organization created = useCase.execute(command());

    ArgumentCaptor<TenantId> tenantCaptor = ArgumentCaptor.forClass(TenantId.class);
    verify(tenantScoped).execute(tenantCaptor.capture(), any());

    // The tenant the transaction was bootstrapped to is the organization's own id — never a
    // tenant that existed before this call, because none did.
    assertThat(tenantCaptor.getValue()).isEqualTo(created.id().asTenantId());
  }

  @Test
  @DisplayName("returns the created organization with the submitted details")
  void returnsTheCreatedOrganization() {
    when(codeDirectory.existsGlobally(any())).thenReturn(false);
    when(organizationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Organization created = useCase.execute(command());

    assertThat(created.code()).isEqualTo(OrganizationCode.of("GREENWOOD"));
    assertThat(created.name()).isEqualTo("Greenwood Education Group");
    assertThat(created.regionProfileCode()).isEqualTo("IN");
  }

  @Test
  @BusinessRule("BR-AUD-002")
  @DisplayName("records an audit entry under the new organization's own tenant")
  void writesAuditRecord() {
    when(codeDirectory.existsGlobally(any())).thenReturn(false);
    when(organizationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Organization created = useCase.execute(command());

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());

    AuditRecord record = captor.getValue();
    assertThat(record.action()).isEqualTo("ORGANIZATION_CREATED");
    assertThat(record.actorId()).isEqualTo(ACTOR);
    assertThat(record.actorRole()).isEqualTo("SUPER_ADMIN");
    assertThat(record.tenantId()).isEqualTo(created.id().asTenantId());
    assertThat(record.afterValues()).containsEntry("code", "GREENWOOD");
  }
}
