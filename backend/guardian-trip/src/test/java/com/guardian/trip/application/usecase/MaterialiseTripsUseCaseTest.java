package com.guardian.trip.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.trip.application.port.RouteTimetableReadModel;
import com.guardian.trip.application.port.TripRepository;
import com.guardian.trip.domain.ScheduledRun;
import com.guardian.trip.domain.TripDirection;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/** Unit tests for trip generation (BR-TRIP-011). */
@ExtendWith(MockitoExtension.class)
class MaterialiseTripsUseCaseTest {

  private static final LocalDate DATE = LocalDate.of(2026, 9, 22);

  @Mock private RouteTimetableReadModel timetable;
  @Mock private TripRepository trips;

  @InjectMocks private MaterialiseTripsUseCase useCase;

  @Test
  @DisplayName("a holiday produces no runs, and the repository is never asked to write")
  void generatesNothingWhenTimetableIsEmpty() {
    when(timetable.runsFor(DATE)).thenReturn(List.of());

    assertThat(useCase.execute(DATE, null)).isZero();

    verify(trips, never()).createScheduled(any(), any(), any());
  }

  @Test
  @DisplayName("every run the timetable expects is handed to the repository for the given date")
  void generatesTheTimetablesRuns() {
    UUID routeId = UUID.randomUUID();
    UUID schoolId = UUID.randomUUID();
    List<ScheduledRun> runs =
        List.of(
            new ScheduledRun(routeId, schoolId, TripDirection.PICKUP, LocalTime.of(7, 15)),
            new ScheduledRun(routeId, schoolId, TripDirection.DROP, LocalTime.of(15, 30)));
    UUID actor = UUID.randomUUID();

    when(timetable.runsFor(DATE)).thenReturn(runs);
    when(trips.createScheduled(runs, DATE, actor)).thenReturn(2);

    assertThat(useCase.execute(DATE, actor)).isEqualTo(2);
  }

  @Test
  @DisplayName("a second run for the same date creates nothing, and that is success")
  void isIdempotent() {
    List<ScheduledRun> runs =
        List.of(
            new ScheduledRun(
                UUID.randomUUID(), UUID.randomUUID(), TripDirection.PICKUP, LocalTime.of(7, 0)));

    when(timetable.runsFor(DATE)).thenReturn(runs);
    // What the database reports after ON CONFLICT DO NOTHING discards the duplicate.
    when(trips.createScheduled(runs, DATE, null)).thenReturn(0);

    assertThat(useCase.execute(DATE, null)).isZero();
  }
}
