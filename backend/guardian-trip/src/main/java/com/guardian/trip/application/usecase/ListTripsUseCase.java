package com.guardian.trip.application.usecase;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.trip.application.port.CrewDirectory;
import com.guardian.trip.application.port.TripRepository;
import com.guardian.trip.domain.Trip;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lists trips for a date — the transport manager's day view, and the crew's own runs.
 *
 * <p>Two methods rather than one with a nullable filter, because they answer different questions
 * and are permitted differently: a manager asks about a school, a crew member asks about
 * themselves. Conflating them would make it easy to let a driver ask about a school.
 */
@Service
public class ListTripsUseCase {

  private final TripRepository trips;
  private final CrewDirectory crew;

  public ListTripsUseCase(TripRepository trips, CrewDirectory crew) {
    this.trips = trips;
    this.crew = crew;
  }

  /** Every run at one school on one date. */
  @Transactional(readOnly = true)
  public List<Trip> forSchool(UUID schoolId, LocalDate serviceDate) {
    return trips.findBySchoolAndDate(schoolId, serviceDate);
  }

  /**
   * The runs the calling user is rostered for.
   *
   * <p>Takes the signed-in user, never a staff id. The driver app asks "what am I on today", and an
   * endpoint that accepted an identifier would be an endpoint that could be asked about somebody
   * else's day — the same reasoning {@code GET /guardians/me/students} applies to a parent.
   *
   * <p>A caller with no staff record is refused rather than handed an empty list: "you are not
   * crew" and "you have no runs today" are different facts, and showing the second for the first
   * sends a driver looking for a rostering problem that does not exist.
   */
  @Transactional(readOnly = true)
  public List<Trip> forCallingCrew(UUID actorUserId, LocalDate serviceDate) {
    UUID staffId =
        crew.staffIdForUser(actorUserId)
            .orElseThrow(
                () ->
                    new BusinessRuleViolationException(
                        ErrorCode.TRIP_NOT_ASSIGNED_CREW,
                        "BR-TRIP-006",
                        Map.of(
                            "reason",
                            "This account is not linked to a transport staff record")));

    return trips.findForStaffOnDate(staffId, serviceDate);
  }
}
