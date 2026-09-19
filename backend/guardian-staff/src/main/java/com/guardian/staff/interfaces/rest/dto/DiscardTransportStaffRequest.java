package com.guardian.staff.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for {@code POST /transport-staff/{id}/discard} (feature STF-007, BR-STAFF-007).
 *
 * <p>{@code reason} is required, unlike a deactivation's: this removes a record permanently, and
 * the audit trail is all that will say why (ADR-0019).
 */
public record DiscardTransportStaffRequest(@NotBlank @Size(max = 500) String reason) {}
