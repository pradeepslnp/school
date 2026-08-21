package com.guardian.absence.interfaces.rest.dto;

import com.guardian.absence.domain.Absence;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Wire form of a declared absence.
 *
 * <p>{@code direction} is null for both journeys, mirroring the request and the column. Round-trip
 * symmetry matters here: the parent app posts this shape and then re-reads it in a list, and a
 * response that renamed "both" to something else would need translation on both sides.
 */
public record AbsenceResponse(
    UUID id,
    UUID studentId,
    LocalDate fromDate,
    LocalDate toDate,
    String direction,
    String reason) {

  public static AbsenceResponse from(Absence absence) {
    return new AbsenceResponse(
        absence.id(),
        absence.studentId(),
        absence.fromDate(),
        absence.toDate(),
        absence.direction() == null ? null : absence.direction().name(),
        absence.reason());
  }
}
