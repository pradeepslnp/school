package com.guardian.trip.application.usecase;

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
import com.guardian.fleet.application.result.VehicleEligibilityResult;
import com.guardian.fleet.application.usecase.GetVehicleEligibilityUseCase;
import com.guardian.staff.application.result.StaffEligibilityResult;
import com.guardian.staff.application.usecase.GetStaffEligibilityUseCase;
import com.guardian.trip.application.command.StartTripCommand;
import com.guardian.trip.application.port.CrewDirectory;
import com.guardian.trip.application.port.TripManifestRepository;
import com.guardian.trip.application.port.TripRepository;
import com.guardian.trip.domain.Trip;
import com.guardian.trip.domain.TripDirection;
import com.guardian.trip.domain.TripStatus;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.List;
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

/**
 * Unit tests for trip start (BR-TRIP-002 to BR-TRIP-006). Ports are mocked; no Spring context, no
 * database.
 *
 * <p>The refusals are tested as carefully as the happy path because each one is a safety gate: a
 * start that slipped past the manifest check would put a bus on the road with no record of who is
 * supposed to be on it.
 */
@ExtendWith(MockitoExtension.class)
class StartTripUseCaseTest {

  private static final UUID TENANT = UUID.randomUUID();
  private static final UUID TRIP = UUID.randomUUID();
  private static final UUID VEHICLE = UUID.randomUUID();
  private static final UUID DRIVER_USER = UUID.randomUUID();
  private static final UUID DRIVER_STAFF = UUID.randomUUID();
  private static final Instant NOW = Instant.parse("2026-09-22T01:30:00Z");

  @Mock private TripRepository trips;
  @Mock private TripManifestRepository manifests;
  @Mock private CrewDirectory crew;
  @Mock private GetVehicleEligibilityUseCase vehicleEligibility;
  @Mock private GetStaffEligibilityUseCase staffEligibility;
  @Mock private AuditPort audit;

  private StartTripUseCase useCase;

  @BeforeEach
  void setUp() {
    TenantContext.set(TenantId.of(TENANT));
    useCase =
        new StartTripUseCase(
            trips,
            manifests,
            crew,
            vehicleEligibility,
            staffEligibility,
            audit,
            Clock.fixed(NOW, ZoneOffset.UTC));
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static Trip tripWith(TripStatus status) {
    return new Trip(
        TRIP,
        UUID.randomUUID(),
        UUID.randomUUID(),
        status == TripStatus.IN_PROGRESS ? VEHICLE : null,
        LocalDate.of(2026, 9, 22),
        TripDirection.PICKUP,
        status,
        LocalTime.of(7, 15),
        null,
        null,
        null,
        null,
        null);
  }

  private StartTripCommand command() {
    return new StartTripCommand(TRIP, VEHICLE, null, DRIVER_USER, "DRIVER");
  }

  private void givenRosteredDriverWithEligibleVehicle() {
    when(crew.staffIdForUser(DRIVER_USER)).thenReturn(Optional.of(DRIVER_STAFF));
    when(trips.isRosteredCrewFor(TRIP, DRIVER_STAFF)).thenReturn(true);
    when(vehicleEligibility.execute(any()))
        .thenReturn(new VehicleEligibilityResult(true, List.of()));
    when(staffEligibility.execute(any())).thenReturn(new StaffEligibilityResult(true, List.of()));
  }

  @Test
  @DisplayName("a rostered driver starts the run, and the manifest is materialised first")
  void startsTheTrip() {
    when(trips.findById(TRIP))
        .thenReturn(Optional.of(tripWith(TripStatus.SCHEDULED)))
        .thenReturn(Optional.of(tripWith(TripStatus.IN_PROGRESS)));
    givenRosteredDriverWithEligibleVehicle();
    when(manifests.countFor(TRIP)).thenReturn(24);
    when(trips.start(TRIP, VEHICLE, NOW, null)).thenReturn(true);

    Trip started = useCase.execute(command());

    assertThat(started.status()).isEqualTo(TripStatus.IN_PROGRESS);
    verify(manifests).materialiseFor(TRIP);

    ArgumentCaptor<AuditRecord> record = ArgumentCaptor.forClass(AuditRecord.class);
    verify(audit).record(record.capture());
    assertThat(record.getValue().action()).isEqualTo("TRIP_STARTED");
  }

  @Test
  @DisplayName("a trip already under way is refused rather than started twice")
  void refusesAlreadyStartedTrip() {
    when(trips.findById(TRIP)).thenReturn(Optional.of(tripWith(TripStatus.IN_PROGRESS)));

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_INVALID_TRANSITION);

    verify(manifests, never()).materialiseFor(any());
    verify(audit, never()).record(any());
  }

  @Test
  @DisplayName("a driver who is not rostered for this run is refused, even holding the permission")
  void refusesUnrosteredDriver() {
    when(trips.findById(TRIP)).thenReturn(Optional.of(tripWith(TripStatus.SCHEDULED)));
    when(crew.staffIdForUser(DRIVER_USER)).thenReturn(Optional.of(DRIVER_STAFF));
    when(trips.isRosteredCrewFor(TRIP, DRIVER_STAFF)).thenReturn(false);

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_NOT_ASSIGNED_CREW);

    verify(trips, never()).start(any(), any(), any(), any());
  }

  @Test
  @DisplayName("a transport manager may start a run they are not rostered for (BR-TRIP-006)")
  void allowsTransportManager() {
    when(trips.findById(TRIP))
        .thenReturn(Optional.of(tripWith(TripStatus.SCHEDULED)))
        .thenReturn(Optional.of(tripWith(TripStatus.IN_PROGRESS)));
    when(crew.staffIdForUser(any())).thenReturn(Optional.empty());
    when(vehicleEligibility.execute(any()))
        .thenReturn(new VehicleEligibilityResult(true, List.of()));
    when(manifests.countFor(TRIP)).thenReturn(12);
    when(trips.start(any(), any(), any(), any())).thenReturn(true);

    Trip started =
        useCase.execute(
            new StartTripCommand(TRIP, VEHICLE, null, UUID.randomUUID(), "TRANSPORT_MANAGER"));

    assertThat(started.status()).isEqualTo(TripStatus.IN_PROGRESS);
  }

  @Test
  @DisplayName("an ineligible vehicle blocks the start and names the failed check")
  void refusesIneligibleVehicle() {
    when(trips.findById(TRIP)).thenReturn(Optional.of(tripWith(TripStatus.SCHEDULED)));
    when(crew.staffIdForUser(DRIVER_USER)).thenReturn(Optional.of(DRIVER_STAFF));
    when(trips.isRosteredCrewFor(TRIP, DRIVER_STAFF)).thenReturn(true);
    when(vehicleEligibility.execute(any()))
        .thenReturn(
            new VehicleEligibilityResult(
                false,
                List.of(
                    new com.guardian.fleet.application.result.EligibilityCheck(
                        "MANDATORY_DOCUMENTS_VALID", false, "Insurance expired", "BR-FLEET-002"))));

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_VEHICLE_NOT_ELIGIBLE);

    verify(manifests, never()).materialiseFor(any());
  }

  @Test
  @DisplayName("an empty manifest blocks the start — better refused at the kerb than at close")
  void refusesEmptyManifest() {
    when(trips.findById(TRIP)).thenReturn(Optional.of(tripWith(TripStatus.SCHEDULED)));
    givenRosteredDriverWithEligibleVehicle();
    when(manifests.countFor(TRIP)).thenReturn(0);

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_MANIFEST_EMPTY);

    verify(trips, never()).start(any(), any(), any(), any());
    verify(audit, never()).record(any());
  }

  @Test
  @DisplayName("losing the start race is reported, not silently treated as success")
  void refusesWhenAnotherCallerStartedFirst() {
    when(trips.findById(TRIP)).thenReturn(Optional.of(tripWith(TripStatus.SCHEDULED)));
    givenRosteredDriverWithEligibleVehicle();
    when(manifests.countFor(TRIP)).thenReturn(18);
    when(trips.start(TRIP, VEHICLE, NOW, null)).thenReturn(false);

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_INVALID_TRANSITION);

    verify(audit, never()).record(any());
  }

  @Test
  @DisplayName("a bus already out on another run cannot be started on a second one (BR-TRIP-005)")
  void refusesVehicleAlreadyOnTrip() {
    when(trips.findById(TRIP)).thenReturn(Optional.of(tripWith(TripStatus.SCHEDULED)));
    givenRosteredDriverWithEligibleVehicle();
    when(trips.vehicleIsOnAnotherTrip(VEHICLE, TRIP)).thenReturn(true);

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_RESOURCE_ALREADY_ON_TRIP);
  }
}
