package com.guardian.trip.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.trip.application.port.TripRepository;
import com.guardian.trip.domain.Trip;
import com.guardian.trip.domain.TripDirection;
import com.guardian.trip.domain.TripStatus;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneOffset;
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

/** Unit tests for cancelling a run (BR-TRIP-007). */
@ExtendWith(MockitoExtension.class)
class CancelTripUseCaseTest {

  private static final UUID TENANT = UUID.randomUUID();
  private static final UUID TRIP = UUID.randomUUID();
  private static final UUID ACTOR = UUID.randomUUID();
  private static final Instant NOW = Instant.parse("2026-09-22T06:40:00Z");

  @Mock private TripRepository trips;
  @Mock private AuditPort audit;

  private CancelTripUseCase useCase;

  @BeforeEach
  void setUp() {
    TenantContext.set(TenantId.of(TENANT));
    useCase = new CancelTripUseCase(trips, audit, Clock.fixed(NOW, ZoneOffset.UTC));
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
        status == TripStatus.IN_PROGRESS ? UUID.randomUUID() : null,
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

  @Test
  @DisplayName("a blank reason is refused before anything is read — guardians are told why")
  void requiresAReason() {
    assertThatThrownBy(() -> useCase.execute(TRIP, "   ", ACTOR, "TRANSPORT_MANAGER"))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_CANCELLATION_REASON_REQUIRED);

    verify(trips, never()).findById(any());
  }

  @Test
  @DisplayName("a scheduled run is cancelled and the reason is carried into the audit record")
  void cancelsScheduledTrip() {
    when(trips.findById(TRIP))
        .thenReturn(Optional.of(tripWith(TripStatus.SCHEDULED)))
        .thenReturn(Optional.of(tripWith(TripStatus.CANCELLED)));
    when(trips.transition(
            eq(TRIP), eq(TripStatus.SCHEDULED), eq(TripStatus.CANCELLED), any(), eq("Breakdown")))
        .thenReturn(true);

    Trip cancelled = useCase.execute(TRIP, "  Breakdown  ", ACTOR, "TRANSPORT_MANAGER");

    assertThat(cancelled.status()).isEqualTo(TripStatus.CANCELLED);

    ArgumentCaptor<AuditRecord> record = ArgumentCaptor.forClass(AuditRecord.class);
    verify(audit).record(record.capture());
    assertThat(record.getValue().action()).isEqualTo("TRIP_CANCELLED");
    assertThat(record.getValue().reason()).isEqualTo("Breakdown");
  }

  @Test
  @DisplayName("a run already over cannot be cancelled retrospectively")
  void refusesCompletedTrip() {
    when(trips.findById(TRIP)).thenReturn(Optional.of(tripWith(TripStatus.COMPLETED)));

    assertThatThrownBy(() -> useCase.execute(TRIP, "Breakdown", ACTOR, "TRANSPORT_MANAGER"))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.TRIP_INVALID_TRANSITION);

    verify(audit, never()).record(any());
  }
}
