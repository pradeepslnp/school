package com.guardian.infrastructure.rest;

import com.guardian.common.rest.CursorPage;
import com.guardian.common.rest.RawResponseBody;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

/**
 * Wraps successful responses in the standard {@code data} envelope
 * (guardian-docs/04-api/API_STANDARDS.md).
 *
 * <p>Applied centrally rather than by each controller returning a wrapper type. Done per
 * controller, the envelope is one forgotten wrapper away from an endpoint that returns a bare
 * object — and the client that breaks is a parent's phone in the field, reading {@code
 * body['data']} and finding nothing.
 *
 * <p>Three things are deliberately left alone:
 *
 * <ul>
 *   <li><strong>Error responses.</strong> They already carry an {@code error} key, written by
 *       {@link GlobalExceptionHandler}, and wrapping an error in {@code data} would make failures
 *       parse as successes.
 *   <li><strong>{@link RawResponseBody} endpoints.</strong> {@code /.well-known/jwks.json} has its
 *       shape fixed by RFC 7517.
 *   <li><strong>Anything that is not JSON</strong> — file downloads, and the actuator, whose
 *       response format is consumed by tooling that knows nothing about this platform.
 * </ul>
 */
@RestControllerAdvice(basePackages = "com.guardian")
public class ResponseEnvelopeAdvice implements ResponseBodyAdvice<Object> {

  @Override
  public boolean supports(
      MethodParameter returnType, Class<? extends HttpMessageConverter<?>> converterType) {
    return returnType.getMethodAnnotation(RawResponseBody.class) == null;
  }

  @Override
  public Object beforeBodyWrite(
      Object body,
      MethodParameter returnType,
      MediaType selectedContentType,
      Class<? extends HttpMessageConverter<?>> selectedConverterType,
      ServerHttpRequest request,
      ServerHttpResponse response) {

    if (!MediaType.APPLICATION_JSON.isCompatibleWith(selectedContentType)) {
      return body;
    }

    // The error envelope is a record, not a Map, so the check below would not catch it and it
    // would be wrapped as {"data": {"error": …}}. Clients read body['error'] to classify a
    // failure; buried under `data` every error would parse as a success with an odd shape.
    if (body instanceof GlobalExceptionHandler.ErrorEnvelope) {
      return body;
    }

    // Already an envelope: a controller built one itself.
    if (body instanceof Map<?, ?> map && (map.containsKey("error") || map.containsKey("data"))) {
      return body;
    }

    // A String return value is written by the String converter, which cannot serialise a Map —
    // wrapping here would throw a ClassCastException at write time rather than produce JSON.
    if (body instanceof String) {
      return body;
    }

    Map<String, Object> meta = new LinkedHashMap<>();
    String requestId = requestId(request);
    if (requestId != null) {
      meta.put("requestId", requestId);
    }
    meta.put("timestamp", Instant.now().toString());

    // A paged collection is unpacked rather than nested: API_STANDARDS.md puts the rows in `data`
    // and the cursor in `meta.pagination`, so a client reads a page exactly as it reads any other
    // collection. Wrapping the carrier whole would put `items` a level deeper than every other
    // list endpoint and make paging a special case for the caller.
    Object payload = body;
    if (body instanceof CursorPage<?> page) {
      Map<String, Object> pagination = new LinkedHashMap<>();
      pagination.put("nextCursor", page.nextCursor());
      pagination.put("limit", page.limit());
      pagination.put("hasMore", page.hasMore());
      meta.put("pagination", pagination);
      payload = page.items();
    }

    Map<String, Object> envelope = new LinkedHashMap<>();
    envelope.put("data", payload);
    envelope.put("meta", meta);
    return envelope;
  }

  private static String requestId(ServerHttpRequest request) {
    if (request instanceof ServletServerHttpRequest servletRequest) {
      HttpServletRequest raw = servletRequest.getServletRequest();
      Object correlationId = raw.getAttribute("correlationId");
      return correlationId == null ? null : correlationId.toString();
    }
    return null;
  }
}
