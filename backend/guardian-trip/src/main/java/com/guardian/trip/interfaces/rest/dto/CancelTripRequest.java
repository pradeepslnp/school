package com.guardian.trip.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * The reason a run is called off.
 *
 * <p>Mandatory, because it is the text affected guardians are shown (BR-TRIP-007). Bounded so a
 * pasted email cannot become a push notification.
 */
public record CancelTripRequest(@NotBlank @Size(max = 500) String reason) {}
