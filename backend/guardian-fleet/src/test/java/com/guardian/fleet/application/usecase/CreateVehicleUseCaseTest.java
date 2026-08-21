package com.guardian.fleet.application.usecase;

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
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.command.CreateVehicleCommand;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.domain.RegistrationNo;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.SeatingCapacity;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleType;
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
class CreateVehicleUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final SchoolId SCHOOL = SchoolId.of(UUID.randomUUID());
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private VehicleRepository vehicleRepository;
  @Mock private AuditPort auditPort;

  private CreateVehicleUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new CreateVehicleUseCase(vehicleRepository, auditPort);
    TenantContext.set(TENANT);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static CreateVehicleCommand aCommand() {
    return new CreateVehicleCommand(
        SCHOOL,
        RegistrationNo.of("DL1PC1234"),
        "Bus 12",
        VehicleType.BUS,
        SeatingCapacity.of(42),
        "Sharma Transport",
        ACTOR,
        "FLEET_MANAGER");
  }

  @Test
  @DisplayName("registers a vehicle with a unique registration number")
  void registersVehicle() {
    when(vehicleRepository.existsByRegistrationNo(any())).thenReturn(false);
    when(vehicleRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Vehicle created = useCase.execute(aCommand());

    assertThat(created.registrationNo().value()).isEqualTo("DL1PC1234");
    assertThat(created.isActive()).isTrue();
  }

  @Test
  @com.guardian.common.BusinessRule("BR-FLEET-001")
  @DisplayName("refuses a registration number already used within the organization")
  void refusesDuplicateRegistration() {
    when(vehicleRepository.existsByRegistrationNo(any())).thenReturn(true);

    assertThatThrownBy(() -> useCase.execute(aCommand()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.VEHICLE_REGISTRATION_EXISTS);

    verify(vehicleRepository, never()).save(any());
    verify(auditPort, never()).record(any());
  }

  @Test
  @com.guardian.common.BusinessRule({"BR-AUD-002", "BR-AUD-003"})
  @DisplayName("records an audit entry carrying actor, role, and the vehicle's initial state")
  void writesAuditRecord() {
    when(vehicleRepository.existsByRegistrationNo(any())).thenReturn(false);
    when(vehicleRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(aCommand());

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());

    AuditRecord record = captor.getValue();
    assertThat(record.action()).isEqualTo("VEHICLE_REGISTERED");
    assertThat(record.actorId()).isEqualTo(ACTOR);
    assertThat(record.actorRole()).isEqualTo("FLEET_MANAGER");
    assertThat(record.tenantId()).isEqualTo(TENANT);
    assertThat(record.afterValues()).containsEntry("registrationNo", "DL1PC1234");
  }
}
