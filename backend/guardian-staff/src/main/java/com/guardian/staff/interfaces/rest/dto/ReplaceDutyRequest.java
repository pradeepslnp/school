package com.guardian.staff.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Wire format for {@code POST /duty-assignments/{id}/replace} (feature STF-004).
 *
 * <p>The replacement inherits the role and direction of the duty it takes over, so neither is sent.
 * {@code reason} is required: every driver or attendant change is recorded with why it happened.
 */
public record ReplaceDutyRequest(@NotNull UUID staffId, @NotBlank @Size(max = 500) String reason) {}
