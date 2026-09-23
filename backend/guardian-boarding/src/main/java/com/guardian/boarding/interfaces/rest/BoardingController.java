package com.guardian.boarding.interfaces.rest;

import com.guardian.boarding.application.command.RecordBoardingCommand;
import com.guardian.boarding.application.usecase.GetTripManifestUseCase;
import com.guardian.boarding.application.usecase.RecordBoardingBatchUseCase;
import com.guardian.boarding.application.usecase.RecordBoardingEventUseCase;
import com.guardian.boarding.domain.BoardingEvent;
import com.guardian.boarding.domain.BoardingEventType;
import com.guardian.boarding.domain.VerificationMethod;
import com.guardian.boarding.interfaces.rest.dto.BatchEventOutcomeResponse;
import com.guardian.boarding.interfaces.rest.dto.BatchResultsResponse;
import com.guardian.boarding.interfaces.rest.dto.BoardingEventResponse;
import com.guardian.boarding.interfaces.rest.dto.ManifestEntryResponse;
import com.guardian.boarding.interfaces.rest.dto.RecordBoardingBatchRequest;
import com.guardian.boarding.interfaces.rest.dto.RecordBoardingRequest;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Boarding endpoints (MOD-09, BRD-001..004, TRP-003).
 *
 * <p>Translation only: every rule — the manifest check, wrong-vehicle detection, the override
 * paths — lives in the use case, because a rule enforced in a controller is a rule the next caller
 * can bypass.
 *
 * <p>Note what the response status says. A first recording is {@code 201}; a retry of one already
 * recorded is {@code 200} with the original record (BR-BOARD-009). The driver app's offline queue
 * depends on that distinction being honest: it retries until it gets either.
 */
@RestController
@RequestMapping("/api/v1/trips/{tripId}")
public class BoardingController {

  private final RecordBoardingEventUseCase recordBoarding;
  private final RecordBoardingBatchUseCase recordBatch;
  private final GetTripManifestUseCase getManifest;

  public BoardingController(
      RecordBoardingEventUseCase recordBoarding,
      RecordBoardingBatchUseCase recordBatch,
      GetTripManifestUseCase getManifest) {
    this.recordBoarding = recordBoarding;
    this.recordBatch = recordBatch;
    this.getManifest = getManifest;
  }

  /** The children this trip expects, in the order the bus meets them. */
  @GetMapping("/manifest")
  @RequiresPermission("PERM-TRIP-VIEW")
  public List<ManifestEntryResponse> manifest(@PathVariable UUID tripId) {
    return getManifest.execute(tripId).stream().map(ManifestEntryResponse::from).toList();
  }

  @PostMapping("/boarding-events")
  @RequiresPermission("PERM-BOARDING-RECORD")
  public BoardingEventResponse record(
      @PathVariable UUID tripId,
      @Valid @RequestBody RecordBoardingRequest request,
      CurrentActor actor) {

    BoardingEvent recorded = recordBoarding.execute(toCommand(tripId, request, actor));
    return BoardingEventResponse.from(recorded);
  }

  private static RecordBoardingCommand toCommand(
      UUID tripId, RecordBoardingRequest request, CurrentActor actor) {
    return new RecordBoardingCommand(
        tripId,
        request.studentId(),
        request.stopId(),
        parseEventType(request.eventType()),
        parseVerificationMethod(request.verificationMethod()),
        request.clientEventId(),
        request.occurredAt(),
        request.clockSkewSeconds(),
        request.latitude(),
        request.longitude(),
        request.isOverride(),
        request.overrideReason(),
        actor.userId(),
        actor.role());
  }

  /**
   * A handset's offline queue, synced (BRD-004, ADR-0008).
   *
   * <p>{@code 202}, not {@code 201}: the batch is <em>accepted</em>, and each event inside it has
   * its own outcome. One event conflicting with server state never discards the rest, and never
   * discards itself either — it is written and flagged (BR-SAFE-005 🔴).
   *
   * <p>Safe to repeat in full. Every event carries its own client id and the server deduplicates
   * on it, which is what lets the driver app retry a whole batch over a fading link without
   * double-recording a busload of children.
   */
  @PostMapping("/boarding-events/batch")
  @ResponseStatus(HttpStatus.ACCEPTED)
  @RequiresPermission("PERM-BOARDING-RECORD")
  public BatchResultsResponse recordBatch(
      @PathVariable UUID tripId,
      @Valid @RequestBody RecordBoardingBatchRequest request,
      CurrentActor actor) {

    List<RecordBoardingCommand> commands =
        request.events().stream().map(event -> toCommand(tripId, event, actor)).toList();

    return new BatchResultsResponse(
        recordBatch.execute(commands).stream().map(BatchEventOutcomeResponse::from).toList());
  }

  /**
   * The append-only guarantee, surfaced (BR-BOARD-001 🔴).
   *
   * <p>These two methods exist to <em>refuse</em>. Without them a {@code PUT} or {@code DELETE}
   * against a boarding event returns Spring's own 405 with no error code and no rule reference,
   * which tells an integrator nothing about why the platform will never allow it. A correction is
   * a new, compensating record.
   */
  @PutMapping("/boarding-events/{eventId}")
  @RequiresPermission("PERM-BOARDING-RECORD")
  public void refuseUpdate(@PathVariable UUID tripId, @PathVariable UUID eventId) {
    throw immutable(eventId);
  }

  @DeleteMapping("/boarding-events/{eventId}")
  @RequiresPermission("PERM-BOARDING-RECORD")
  public void refuseDelete(@PathVariable UUID tripId, @PathVariable UUID eventId) {
    throw immutable(eventId);
  }

  private static BusinessRuleViolationException immutable(UUID eventId) {
    return new BusinessRuleViolationException(
        ErrorCode.BOARDING_EVENT_IMMUTABLE,
        "BR-BOARD-001",
        Map.of(
            "eventId", eventId.toString(),
            "remedy", "Record a compensating correction instead"));
  }

  private static BoardingEventType parseEventType(String wire) {
    try {
      return BoardingEventType.valueOf(wire.toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException e) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT, "BR-BOARD-002", Map.of("field", "eventType"));
    }
  }

  private static VerificationMethod parseVerificationMethod(String wire) {
    if (wire == null || wire.isBlank()) {
      // Defaulting to MANUAL is honest: the crew selected the child from the manifest, which is
      // exactly what MANUAL means. Defaulting to QR_SCAN would record a scan that never happened.
      return VerificationMethod.MANUAL;
    }
    try {
      return VerificationMethod.valueOf(wire.toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException e) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT,
          "BR-BOARD-002",
          Map.of("field", "verificationMethod"));
    }
  }
}
