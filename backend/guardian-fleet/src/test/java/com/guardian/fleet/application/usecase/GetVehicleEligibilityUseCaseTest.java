package com.guardian.fleet.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.guardian.common.BusinessRule;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.port.VehicleDocumentRepository;
import com.guardian.fleet.application.port.VehicleRepository;
import com.guardian.fleet.application.result.VehicleEligibilityResult;
import com.guardian.fleet.domain.RegistrationNo;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.SeatingCapacity;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleDocument;
import com.guardian.fleet.domain.VehicleId;
import com.guardian.fleet.domain.VehicleStatus;
import com.guardian.fleet.domain.VehicleType;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Unit tests for the vehicle half of trip-start eligibility
 * (guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md, "Trip-Start Eligibility").
 */
@ExtendWith(MockitoExtension.class)
class GetVehicleEligibilityUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final Clock FIXED_CLOCK =
      Clock.fixed(Instant.parse("2026-08-03T00:00:00Z"), ZoneOffset.UTC);

  @Mock private VehicleRepository vehicleRepository;
  @Mock private VehicleDocumentRepository documentRepository;

  private GetVehicleEligibilityUseCase useCase;
  private VehicleId vehicleId;

  @BeforeEach
  void setUp() {
    useCase = new GetVehicleEligibilityUseCase(vehicleRepository, documentRepository, FIXED_CLOCK);
    vehicleId = VehicleId.generate();
  }

  private Vehicle activeVehicle() {
    return new Vehicle(
        vehicleId,
        TENANT,
        SchoolId.of(UUID.randomUUID()),
        RegistrationNo.of("DL1PC1234"),
        "Bus 12",
        VehicleType.BUS,
        SeatingCapacity.of(42),
        null,
        VehicleStatus.ACTIVE,
        0L);
  }

  @Test
  @DisplayName("an active vehicle with no expired mandatory document is eligible")
  void eligibleWhenActiveAndCompliant() {
    when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(activeVehicle()));
    when(documentRepository.findMandatoryByVehicle(vehicleId)).thenReturn(List.of());

    VehicleEligibilityResult result = useCase.execute(vehicleId);

    assertThat(result.eligible()).isTrue();
    assertThat(result.checks()).allMatch(c -> c.passed());
  }

  @Test
  @BusinessRule("BR-FLEET-002")
  @DisplayName("an expired mandatory document makes the vehicle ineligible, naming the check")
  void ineligibleWhenAMandatoryDocumentHasExpired() {
    VehicleDocument expired =
        VehicleDocument.create(
            TENANT,
            vehicleId,
            "FITNESS_CERTIFICATE",
            "FC-1",
            null,
            LocalDate.of(2026, 7, 15),
            true,
            null);

    when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(activeVehicle()));
    when(documentRepository.findMandatoryByVehicle(vehicleId)).thenReturn(List.of(expired));

    VehicleEligibilityResult result = useCase.execute(vehicleId);

    assertThat(result.eligible()).isFalse();
    assertThat(result.checks())
        .anySatisfy(
            check -> {
              assertThat(check.check()).isEqualTo("MANDATORY_DOCUMENTS_VALID");
              assertThat(check.passed()).isFalse();
              assertThat(check.businessRule()).isEqualTo("BR-FLEET-002");
            });
  }

  @Test
  @DisplayName("a vehicle in maintenance is ineligible even with valid documents")
  void ineligibleWhenNotActive() {
    Vehicle inMaintenance = activeVehicle().changeStatus(VehicleStatus.MAINTENANCE);
    when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(inMaintenance));
    when(documentRepository.findMandatoryByVehicle(vehicleId)).thenReturn(List.of());

    VehicleEligibilityResult result = useCase.execute(vehicleId);

    assertThat(result.eligible()).isFalse();
  }

  @Test
  @DisplayName("a document expiring exactly today is not yet expired")
  void documentExpiringTodayIsNotExpired() {
    VehicleDocument expiresToday =
        VehicleDocument.create(
            TENANT, vehicleId, "INSURANCE", "IN-1", null, LocalDate.of(2026, 8, 3), true, null);

    when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(activeVehicle()));
    when(documentRepository.findMandatoryByVehicle(vehicleId)).thenReturn(List.of(expiresToday));

    assertThat(useCase.execute(vehicleId).eligible()).isTrue();
  }
}
