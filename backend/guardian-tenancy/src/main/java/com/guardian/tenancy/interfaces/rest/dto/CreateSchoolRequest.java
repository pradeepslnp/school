package com.guardian.tenancy.interfaces.rest.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * Wire format for creating a school.
 *
 * <p>Bean validation catches malformed input at the boundary; domain value objects re-check the
 * invariants they own. The duplication is intentional — the domain must remain correct when called
 * from a job or a test that never passes through this DTO.
 *
 * @param timezone IANA identifier. Required, never defaulted: every displayed time depends on it
 *     (BR-CFG-006), and defaulting to server time is silently wrong for any school outside the
 *     server's zone.
 */
public record CreateSchoolRequest(
    @NotNull UUID organizationId,
    @NotBlank String code,
    @NotBlank String name,
    @NotBlank String timezone,
    @NotNull @DecimalMin("-90") @DecimalMax("90") BigDecimal latitude,
    @NotNull @DecimalMin("-180") @DecimalMax("180") BigDecimal longitude,
    @NotNull @Min(20) @Max(2000) Integer geofenceRadiusM) {}
