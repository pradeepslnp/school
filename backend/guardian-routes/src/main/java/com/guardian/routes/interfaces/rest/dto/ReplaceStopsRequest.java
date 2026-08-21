package com.guardian.routes.interfaces.rest.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

/** Wire format for {@code PUT /routes/{id}/stops} (feature RTE-001). */
public record ReplaceStopsRequest(@NotEmpty @Valid List<StopRequest> stops) {}
