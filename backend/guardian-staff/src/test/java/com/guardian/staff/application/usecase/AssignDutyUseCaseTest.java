package com.guardian.staff.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.AssignDutyCommand;
import com.guardian.staff.application.port.DutyAssignmentRepository;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.Direction;
import com.guardian.staff.domain.DutyAssignment;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.TransportStaff;
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
class AssignDutyUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final RouteId ROUTE = RouteId.of(UUID.randomUUID());
  private static final StaffId STAFF = StaffId.of(UUID.randomUUID());
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private DutyAssignmentRepository dutyAssignmentRepository;
  @Mock private TransportStaffRepository transportStaffRepository;
  @Mock private AuditPort auditPort;

  private AssignDutyUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new AssignDutyUseCase(dutyAssignmentRepository, transportStaffRepository, auditPort);
    TenantContext.set(TENANT);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static TransportStaff staffOfType(StaffType type) {
    return TransportStaff.create(
        TENANT,
        SchoolId.of(UUID.randomUUID()),
        type,
        "EMP-1",
        "Suresh",
        "Kumar",
        "9000000001",
        null);
  }

  private void givenStaffIsA(StaffType type) {
    when(transportStaffRepository.findById(STAFF)).thenReturn(Optional.of(staffOfType(type)));
  }

  @Test
  @DisplayName("assigns a driver to a route")
  void assignsDriver() {
    givenStaffIsA(StaffType.DRIVER);
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
    givenStaffIsA(StaffType.ATTENDANT);
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

  @Test
  @DisplayName("an attendant cannot be rostered as the route's driver")
  void refusesRoleMismatch() {
    givenStaffIsA(StaffType.ATTENDANT);

    assertThatThrownBy(
            () ->
                useCase.execute(
                    new AssignDutyCommand(
                        ROUTE,
                        STAFF,
                        StaffType.DRIVER,
                        Direction.PICKUP,
                        ACTOR,
                        "TRANSPORT_MANAGER")))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.STAFF_ROLE_MISMATCH);

    // Caught before anything is written: the office sees it now, not the driver at the kerb.
    verify(dutyAssignmentRepository, never()).save(any());
    verify(auditPort, never()).record(any());
  }

  @Test
  @DisplayName("an unknown staff member is refused before the roster is touched")
  void refusesUnknownStaff() {
    when(transportStaffRepository.findById(STAFF)).thenReturn(Optional.empty());

    assertThatThrownBy(
            () ->
                useCase.execute(
                    new AssignDutyCommand(
                        ROUTE,
                        STAFF,
                        StaffType.DRIVER,
                        Direction.PICKUP,
                        ACTOR,
                        "TRANSPORT_MANAGER")))
        .isInstanceOf(com.guardian.common.error.ResourceNotFoundException.class);

    verify(dutyAssignmentRepository, never()).save(any());
  }
}
