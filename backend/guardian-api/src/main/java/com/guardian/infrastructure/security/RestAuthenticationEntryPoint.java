package com.guardian.infrastructure.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.guardian.common.error.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

/**
 * Answers an unauthenticated request in the platform's error envelope.
 *
 * <p>Spring Security's default sends a bare {@code 401} with a {@code WWW-Authenticate} header,
 * which the mobile clients cannot parse — they read {@code error.code} and {@code error.messageKey}
 * and would fall back to "unknown error" for the single most common failure there is.
 *
 * <p>Always {@code AUTH_TOKEN_MISSING}, whatever went wrong. A missing token, an expired one, a
 * revoked one, and a forgery all arrive here identically on purpose: the client's response to all
 * four is the same — refresh, or sign in again — and naming which one applies tells whoever sent
 * the token how far they got.
 */
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

  private final ObjectMapper objectMapper;

  public RestAuthenticationEntryPoint(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  @Override
  public void commence(
      HttpServletRequest request,
      HttpServletResponse response,
      AuthenticationException authException)
      throws IOException {

    ErrorCode code = ErrorCode.AUTH_TOKEN_MISSING;

    Map<String, Object> error = new LinkedHashMap<>();
    error.put("code", code.name());
    // Clients render from the localisation key, never a server-supplied string (BR-CFG-005).
    error.put("messageKey", code.messageKey());
    Object correlationId = request.getAttribute("correlationId");
    if (correlationId != null) {
      error.put("requestId", correlationId.toString());
    }
    error.put("timestamp", Instant.now().toString());

    response.setStatus(code.httpStatus());
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    objectMapper.writeValue(response.getOutputStream(), Map.of("error", error));
  }
}
