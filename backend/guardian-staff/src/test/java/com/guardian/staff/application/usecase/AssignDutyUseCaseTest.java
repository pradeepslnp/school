package com.guardian.staff.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.AssignDutyCommand;
import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.domain.Direction;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
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
class AssignDutyUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final RouteId ROUTE = RouteId.of(UUID.randomUUID());
  private static final StaffId STAFF = StaffId.of(UUID.randomUUID());
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private DutyAssignmentRepository dutyAssignmentRepository;
  @Mock private AuditPort auditPort;

  private AssignDutyUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new AssignDutyUseCase(dutyAssignmentRepository, auditPort);
    TenantContext.set(TENANT);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  @Test
  @DisplayName("assigns a driver to a route")
  void assignsDriver() {
    when(dutyAssignmentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    DutyAssignment created =
        useCase.execute(
            new AssignDutyCommand(
                ROUTE, STAFF, StaffType.DRIVER, Direction.PICKUP, ACTOR, "TRANSPORT_MANAGER"));

    assertThat(created.role()).isEqualTo(StaffType.DRIVER);
    assertThat(created.active()).isTrue();
  }

  @Test
  @com.guardian.common.BusinessRule("BR-AUD-002")
  @DisplayName("records an audit entry carrying actor, role, and route")
  void writesAuditRecord() {
    when(dutyAssignmentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(
        new AssignDutyCommand(ROUTE, STAFF, StaffType.ATTENDANT, null, ACTOR, "TRANSPORT_MANAGER"));

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());

    AuditRecord record = captor.getValue();
    assertThat(record.action()).isEqualTo("DUTY_ASSIGNED");
    assertThat(record.actorId()).isEqualTo(ACTOR);
    assertThat(record.tenantId()).isEqualTo(TENANT);
  }
}
