package com.guardian.staff.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** Wire format for assigning a driver or attendant to a route (feature STF-004). */
public record AssignDutyRequest(@NotNull UUID staffId, @NotBlank String role, String direction) {}
