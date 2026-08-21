package com.guardian.staff.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.CreateTransportStaffCommand;
import com.guardian.staff.application.port.StaffAccountProvisioningPort;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.TransportStaff;
import com.guardian.staff.domain.UserId;
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
class CreateTransportStaffUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private TransportStaffRepository staffRepository;
  @Mock private StaffAccountProvisioningPort accountProvisioning;
  @Mock private AuditPort auditPort;

  private CreateTransportStaffUseCase useCase;

  @BeforeEach
  void setUp() {
    TenantContext.set(TENANT);
    useCase = new CreateTransportStaffUseCase(staffRepository, accountProvisioning, auditPort);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static CreateTransportStaffCommand command() {
    return new CreateTransportStaffCommand(
        SchoolId.of(UUID.randomUUID()),
        StaffType.DRIVER,
        "EMP-001",
        "Ravi",
        "Kumar",
        "9876500001",
        null,
        ACTOR,
        "TRANSPORT_MANAGER");
  }

  @Test
  @DisplayName("provisions a login and links it onto the staff record, in the same flow")
  void provisionsAndLinksTheAccount() {
    UUID provisionedUserId = UUID.randomUUID();
    when(staffRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    when(accountProvisioning.provision(any(), any(), any(), any(), any(), any()))
        .thenReturn(UserId.of(provisionedUserId));

    TransportStaff result = useCase.execute(command());

    assertThat(result.userId()).contains(UserId.of(provisionedUserId));
  }

  @Test
  @DisplayName("asks the provisioning port for the role the staff type implies")
  void provisionsUsingStaffTypeAndContactDetails() {
    when(staffRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    when(accountProvisioning.provision(any(), any(), any(), any(), any(), any()))
        .thenReturn(UserId.of(UUID.randomUUID()));

    useCase.execute(command());

    ArgumentCaptor<StaffType> staffTypeCaptor = ArgumentCaptor.forClass(StaffType.class);
    ArgumentCaptor<String> phoneCaptor = ArgumentCaptor.forClass(String.class);
    verify(accountProvisioning)
        .provision(staffTypeCaptor.capture(), phoneCaptor.capture(), any(), any(), any(), any());

    assertThat(staffTypeCaptor.getValue()).isEqualTo(StaffType.DRIVER);
    assertThat(phoneCaptor.getValue()).isEqualTo("9876500001");
  }

  @Test
  @DisplayName("records an audit entry for the linked staff record")
  void writesAuditRecordForTheLinkedRecord() {
    UUID provisionedUserId = UUID.randomUUID();
    when(staffRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    when(accountProvisioning.provision(any(), any(), any(), any(), any(), any()))
        .thenReturn(UserId.of(provisionedUserId));

    useCase.execute(command());

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());
    assertThat(captor.getValue().action()).isEqualTo("TRANSPORT_STAFF_CREATED");
  }
}
