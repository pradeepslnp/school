package com.guardian.boarding.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.boarding.application.command.RecordBoardingCommand;
import com.guardian.boarding.application.port.BoardingEventRepository;
import com.guardian.boarding.application.port.TripManifestReadModel;
import com.guardian.boarding.domain.BoardingEvent;
import com.guardian.boarding.domain.BoardingEventType;
import com.guardian.boarding.domain.ManifestEntryStatus;
import com.guardian.boarding.domain.VerificationMethod;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Unit tests for the platform's most safety-critical write (BRD-001..004, BR-SAFE-003).
 *
 * <p>The refusals get more attention than the happy path, because each one is a child being kept
 * off the wrong bus or an unaccounted record being prevented.
 */
@ExtendWith(MockitoExtension.class)
class RecordBoardingEventUseCaseTest {

  private static final UUID TENANT = UUID.randomUUID();
  private static final UUID TRIP = UUID.randomUUID();
  private static final UUID STUDENT = UUID.randomUUID();
  private static final UUID STOP = UUID.randomUUID();
  private static final UUID ACTOR = UUID.randomUUID();
  private static final UUID CLIENT_EVENT = UUID.randomUUID();
  private static final Instant NOW = Instant.parse("2026-09-23T07:42:00Z");

  @Mock private BoardingEventRepository events;
  @Mock private TripManifestReadModel trips;
  @Mock private AuditPort audit;

  private RecordBoardingEventUseCase useCase;

  @BeforeEach
  void setUp() {
    TenantContext.set(TenantId.of(TENANT));
    useCase =
        new RecordBoardingEventUseCase(events, trips, audit, Clock.fixed(NOW, ZoneOffset.UTC));
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private RecordBoardingCommand board() {
    return command(BoardingEventType.BOARD, STOP, false, null);
  }

  private RecordBoardingCommand command(
      BoardingEventType type, UUID stopId, boolean isOverride, String reason) {
    return new RecordBoardingCommand(
        TRIP,
        STUDENT,
        stopId,
        type,
        VerificationMethod.MANUAL,
        CLIENT_EVENT,
        NOW,
        null,
        null,
        null,
        isOverride,
        reason,
        ACTOR,
        "ATTENDANT");
  }

  private void givenRunningTripWithStudentOnManifest() {
    when(trips.statusOf(TRIP)).thenReturn(Optional.of("IN_PROGRESS"));
    when(events.findByClientEventId(CLIENT_EVENT)).thenReturn(Optional.empty());
    when(events.isOnManifest(TRIP, STUDENT)).thenReturn(true);
    when(events.append(any())).thenAnswer(inv -> inv.getArgument(0));
  }

  @Test
  @DisplayName("records a boarding and moves the manifest row to BOARDED")
  void recordsBoarding() {
    givenRunningTripWithStudentOnManifest();
    when(events.lastEventTypeFor(TRIP, STUDENT)).thenReturn(Optional.empty());

    BoardingEvent recorded = useCase.execute(board());

    assertThat(recorded.eventType()).isEqualTo(BoardingEventType.BOARD);
    verify(events).updateManifestStatus(TRIP, STUDENT, ManifestEntryStatus.BOARDED);
    verify(audit).record(any());
  }

  @Test
  @DisplayName("a retried event returns the original record and writes nothing (BR-BOARD-009)")
  void isIdempotent() {
    BoardingEvent original =
        new BoardingEvent(
            UUID.randomUUID(),
            TRIP,
            STUDENT,
            STOP,
            BoardingEventType.BOARD,
            VerificationMethod.MANUAL,
            ACTOR,
            "ATTENDANT",
            CLIENT_EVENT,
            null,
            false,
            null,
            NOW,
            NOW,
            null,
            null,
            null);
    when(events.findByClientEventId(CLIENT_EVENT)).thenReturn(Optional.of(original));

    assertThat(useCase.execute(board())).isEqualTo(original);

    // Critically, the rules are never reached: an offline event retried after the child has since
    // alighted must not be refused with "already boarded".
    verify(events, never()).append(any());
    verify(audit, never()).record(any());
  }

  @Test
  @DisplayName("a child expected on another running trip is refused, and cannot be overridden")
  void refusesWrongVehicleEvenWithOverride() {
    when(trips.statusOf(TRIP)).thenReturn(Optional.of("IN_PROGRESS"));
    when(events.findByClientEventId(CLIENT_EVENT)).thenReturn(Optional.empty());
    when(events.isOnManifest(TRIP, STUDENT)).thenReturn(false);
    when(events.otherTripExpectingStudent(TRIP, STUDENT))
        .thenReturn(Optional.of(UUID.randomUUID()));

    assertThatThrownBy(
            () ->
                useCase.execute(
                    command(BoardingEventType.BOARD, STOP, true, "Attendant says it is fine")))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.BOARDING_WRONG_VEHICLE);

    verify(events, never()).append(any());
  }

  @Test
  @DisplayName("a child not on the manifest is refused, but an override with a reason proceeds")
  void offManifestNeedsOverride() {
    when(trips.statusOf(TRIP)).thenReturn(Optional.of("IN_PROGRESS"));
    when(events.findByClientEventId(CLIENT_EVENT)).thenReturn(Optional.empty());
    when(events.isOnManifest(TRIP, STUDENT)).thenReturn(false);
    when(events.otherTripExpectingStudent(TRIP, STUDENT)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> useCase.execute(board()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.BOARDING_STUDENT_NOT_ON_MANIFEST);
  }

  @Test
  @DisplayName("an override with no reason is refused — an unexplained override is not evidence")
  void overrideNeedsReason() {
    when(trips.statusOf(TRIP)).thenReturn(Optional.of("IN_PROGRESS"));
    when(events.findByClientEventId(CLIENT_EVENT)).thenReturn(Optional.empty());
    when(events.isOnManifest(TRIP, STUDENT)).thenReturn(false);
    when(events.otherTripExpectingStudent(TRIP, STUDENT)).thenReturn(Optional.empty());

    assertThatThrownBy(
            () -> useCase.execute(command(BoardingEventType.BOARD, STOP, true, "   ")))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.BOARDING_OVERRIDE_REASON_REQUIRED);
  }

  @Test
  @DisplayName("boarding twice with no alight between is refused outright (BR-BOARD-005)")
  void refusesDoubleBoard() {
    givenRunningTripWithStudentOnManifest();
    when(events.lastEventTypeFor(TRIP, STUDENT)).thenReturn(Optional.of(BoardingEventType.BOARD));

    assertThatThrownBy(() -> useCase.execute(board()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.BOARDING_ALREADY_BOARDED);

    verify(events, never()).append(any());
  }

  @Test
  @DisplayName("alighting a child who never boarded is refused (BR-BOARD-006)")
  void refusesAlightWithoutBoard() {
    when(trips.statusOf(TRIP)).thenReturn(Optional.of("IN_PROGRESS"));
    when(events.findByClientEventId(CLIENT_EVENT)).thenReturn(Optional.empty());
    when(events.isOnManifest(TRIP, STUDENT)).thenReturn(true);
    when(events.lastEventTypeFor(TRIP, STUDENT)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> useCase.execute(command(BoardingEventType.ALIGHT, STOP, false, null)))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.BOARDING_NOT_BOARDED);
  }

  @Test
  @DisplayName("alighting at somebody else's stop is refused without an override (BR-BOARD-004)")
  void refusesWrongStop() {
    when(trips.statusOf(TRIP)).thenReturn(Optional.of("IN_PROGRESS"));
    when(events.findByClientEventId(CLIENT_EVENT)).thenReturn(Optional.empty());
    when(events.isOnManifest(TRIP, STUDENT)).thenReturn(true);
    when(events.lastEventTypeFor(TRIP, STUDENT)).thenReturn(Optional.of(BoardingEventType.BOARD));
    when(events.expectedStopFor(TRIP, STUDENT)).thenReturn(Optional.of(UUID.randomUUID()));

    assertThatThrownBy(() -> useCase.execute(command(BoardingEventType.ALIGHT, STOP, false, null)))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.BOARDING_WRONG_STOP);
  }

  @Test
  @DisplayName("nothing may be recorded against a run that has not started")
  void refusesTripNotStarted() {
    when(events.findByClientEventId(CLIENT_EVENT)).thenReturn(Optional.empty());
    when(trips.statusOf(TRIP)).thenReturn(Optional.of("SCHEDULED"));

    assertThatThrownBy(() -> useCase.execute(board()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_NOT_STARTED);
  }
}
