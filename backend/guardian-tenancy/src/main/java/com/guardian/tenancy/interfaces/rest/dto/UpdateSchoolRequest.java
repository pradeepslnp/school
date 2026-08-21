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
 * Wire format for editing a school. No {@code code}: it is immutable once the organization has
 * operational data (BR-TEN-007), and no endpoint changes it.
 *
 * @param organizationId required so the server can establish the right tenant context before
 *     reading the row — see {@code UpdateSchoolCommand}'s documentation. Re-sent rather than
 *     inferred, matching {@code CreateSchoolRequest}.
 */
public record UpdateSchoolRequest(
    @NotNull UUID organizationId,
    @NotBlank String name,
    @NotBlank String timezone,
    @NotNull @DecimalMin("-90") @DecimalMax("90") BigDecimal latitude,
    @NotNull @DecimalMin("-180") @DecimalMax("180") BigDecimal longitude,
    @NotNull @Min(20) @Max(2000) Integer geofenceRadiusM) {}
