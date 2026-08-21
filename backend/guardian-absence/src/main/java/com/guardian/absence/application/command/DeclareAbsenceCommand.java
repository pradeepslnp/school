package com.guardian.absence.application.command;

import com.guardian.absence.domain.Absence;
import java.time.LocalDate;
import java.util.UUID;

/** Input to {@code DeclareAbsenceUseCase}. Wire concerns are already gone by this point. */
public record DeclareAbsenceCommand(
    UUID studentId,
    LocalDate fromDate,
    LocalDate toDate,
    /* Null means both journeys (BR-ABS-001). */
    Absence.Direction direction,
    String reason,
    UUID actorUserId,
    String actorRole) {}
