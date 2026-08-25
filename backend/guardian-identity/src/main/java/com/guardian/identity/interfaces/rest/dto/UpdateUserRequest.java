package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/** Wire format for editing an administrative account's name and locale (screen A-43). */
public record UpdateUserRequest(
    @NotNull UUID organizationId,
    @NotBlank @Size(max = 128) String firstName,
    @NotBlank @Size(max = 128) String lastName,
    @NotBlank @Size(max = 16) String preferredLocale) {}
