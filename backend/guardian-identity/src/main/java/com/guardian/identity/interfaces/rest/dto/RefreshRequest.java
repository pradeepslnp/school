package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Wire format for {@code POST /auth/refresh}. */
public record RefreshRequest(@NotBlank @Size(max = 512) String refreshToken) {}
