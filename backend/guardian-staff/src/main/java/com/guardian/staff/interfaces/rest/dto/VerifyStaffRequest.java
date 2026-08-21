package com.guardian.staff.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * Wire format for {@code POST /transport-staff/{id}/verify} (guardian-docs/04-api/
 * FLEET_STAFF_ROUTES_API.md). {@code verifiedUntil} is required — BR-STAFF-002 🔴.
 */
public record VerifyStaffRequest(
    @NotBlank String verificationType, @NotNull LocalDate verifiedUntil, String referenceNumber) {}
