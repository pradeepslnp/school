package com.guardian.staff.application.command;

import com.guardian.staff.domain.Direction;
import com.guardian.staff.domain.RouteId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import java.util.UUID;

/** Input to {@code AssignDutyUseCase} (feature STF-004). */
public record AssignDutyCommand(
    RouteId routeId,
    StaffId staffId,
    StaffType role,
    Direction direction,
    UUID actorId,
    String actorRole) {}
