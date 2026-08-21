package com.guardian.infrastructure.rest;

import com.fasterxml.jackson.databind.exc.InvalidFormatException;
import com.guardian.common.error.DomainException;
import com.guardian.common.error.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Maps exceptions to the standard error envelope (guardian-docs/04-api/API_STANDARDS.md).
 *
 * <p>One handler for the whole application. Exceptions are never caught and rethrown at multiple
 * layers, and never swallowed (ENGINEERING_PRINCIPLES.md §12).
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

  private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

  @ExceptionHandler(DomainException.class)
  public ResponseEntity<ErrorEnvelope> handleDomain(DomainException e, HttpServletRequest request) {
    ErrorCode code = e.errorCode();

    List<ErrorEnvelope.Detail> details =
        e.context().entrySet().stream()
            .map(
                entry -> new ErrorEnvelope.Detail(entry.getKey(), String.valueOf(entry.getValue())))
            .toList();

    // `businessRule` is populated deliberately: a driver refused at 06:30 needs to know
    // which check failed, and support needs to find the rule without reading source.
    return ResponseEntity.status(code.httpStatus())
        .body(ErrorEnvelope.of(code, details, e.businessRule(), requestId(request)));
  }

  /**
   * An endpoint requiring an actor was reached without one.
   *
   * <p>401 rather than 500: the caller's remedy is to authenticate. See {@link
   * CurrentActorArgumentResolver} for why this is a hard failure instead of a null actor.
   */
  @ExceptionHandler(CurrentActorArgumentResolver.MissingActorException.class)
  public ResponseEntity<ErrorEnvelope> handleMissingActor(
      CurrentActorArgumentResolver.MissingActorException e, HttpServletRequest request) {
    return ResponseEntity.status(ErrorCode.AUTH_TOKEN_MISSING.httpStatus())
        .body(ErrorEnvelope.of(ErrorCode.AUTH_TOKEN_MISSING, List.of(), null, requestId(request)));
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ErrorEnvelope> handleValidation(
      MethodArgumentNotValidException e, HttpServletRequest request) {

    // All field errors at once — a bulk form should not require six round trips.
    List<ErrorEnvelope.Detail> details = new ArrayList<>();
    e.getBindingResult()
        .getFieldErrors()
        .forEach(
            error ->
                details.add(new ErrorEnvelope.Detail(error.getField(), error.getDefaultMessage())));

    return ResponseEntity.status(ErrorCode.VALIDATION_FAILED.httpStatus())
        .body(ErrorEnvelope.of(ErrorCode.VALIDATION_FAILED, details, null, requestId(request)));
  }

  /**
   * A request body that does not even parse into the DTO — most often a field typed as the wrong
   * shape, such as a school code entered where a school's UUID belongs. This is the caller's
   * mistake, not the server's, so it is reported the same way {@link
   * MethodArgumentNotValidException} is rather than falling through to a 500.
   */
  @ExceptionHandler(HttpMessageNotReadableException.class)
  public ResponseEntity<ErrorEnvelope> handleUnreadableBody(
      HttpMessageNotReadableException e, HttpServletRequest request) {

    List<ErrorEnvelope.Detail> details = new ArrayList<>();
    if (e.getCause() instanceof InvalidFormatException ife && !ife.getPath().isEmpty()) {
      String field = ife.getPath().get(ife.getPath().size() - 1).getFieldName();
      details.add(
          new ErrorEnvelope.Detail(
              field, "must be a valid " + ife.getTargetType().getSimpleName()));
    }

    return ResponseEntity.status(ErrorCode.VALIDATION_INVALID_FORMAT.httpStatus())
        .body(
            ErrorEnvelope.of(
                ErrorCode.VALIDATION_INVALID_FORMAT, details, null, requestId(request)));
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorEnvelope> handleUnexpected(Exception e, HttpServletRequest request) {
    String requestId = requestId(request);
    log.error("Unhandled exception requestId={}", requestId, e);

    // Nothing internal is returned to the client — only the request ID, so support can
    // correlate with logs (guardian-docs/02-system-design/SECURITY_ARCHITECTURE.md).
    return ResponseEntity.status(ErrorCode.INTERNAL_ERROR.httpStatus())
        .body(ErrorEnvelope.of(ErrorCode.INTERNAL_ERROR, List.of(), null, requestId));
  }

  private static String requestId(HttpServletRequest request) {
    Object correlationId = request.getAttribute("correlationId");
    return correlationId == null ? null : correlationId.toString();
  }

  /** The error envelope described in guardian-docs/04-api/API_STANDARDS.md. */
  public record ErrorEnvelope(Map<String, Object> error) {

    record Detail(String field, String issue) {}

    static ErrorEnvelope of(
        ErrorCode code, List<Detail> details, String businessRule, String requestId) {
      Map<String, Object> error = new java.util.LinkedHashMap<>();
      error.put("code", code.name());
      // Clients display from the localisation key, never from a server-supplied string
      // (BR-CFG-005).
      error.put("messageKey", code.messageKey());
      if (!details.isEmpty()) {
        error.put("details", details);
      }
      if (businessRule != null) {
        error.put("businessRule", businessRule);
      }
      if (requestId != null) {
        error.put("requestId", requestId);
      }
      error.put("timestamp", Instant.now().toString());
      return new ErrorEnvelope(error);
    }
  }
}
