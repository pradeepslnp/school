package com.guardian.boarding.interfaces.rest.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * A handset's queue of events, synced when the signal came back (BRD-004, ADR-0008).
 *
 * <p>Bounded at 200. A crew's queue after a morning with no signal is tens of events, not
 * thousands; a larger body is a bug or an attack, and refusing it protects the one transaction
 * budget this endpoint has.
 */
public record RecordBoardingBatchRequest(
    @NotEmpty @Size(max = 200) @Valid List<RecordBoardingRequest> events) {}
