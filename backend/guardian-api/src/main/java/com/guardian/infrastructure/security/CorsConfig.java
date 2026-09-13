package com.guardian.infrastructure.security;

import com.guardian.infrastructure.tenant.PlatformElevation;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/**
 * Cross-origin policy for the browser clients.
 *
 * <p>The admin console (ADR-0003) is a Flutter Web build served from its own origin and calling
 * this API on another. Without the headers configured here the browser refuses every request before
 * it is sent, and the console reports the API as unreachable — which is indistinguishable, from
 * Dart, from the server being down. The two mobile apps are unaffected: the same-origin policy is a
 * browser rule, not an HTTP one.
 *
 * <p><strong>Credentials are not allowed, deliberately.</strong> This API authenticates with a
 * bearer token in the {@code Authorization} header, which the browser attaches only because the
 * client asked it to. Setting {@code allowCredentials} would additionally permit cookies to ride
 * along on cross-origin requests, which is how a CSRF becomes possible against an API that has
 * (correctly) disabled CSRF protection on the grounds that it uses no cookies. If the refresh token
 * ever moves to an {@code HttpOnly} cookie — the fix recorded in the admin console's README for
 * session persistence — this must change to {@code true} <em>and</em> {@link #allowedOrigins} must
 * become an exact list with no patterns, because a wildcard with credentials is refused by the
 * specification and by Spring.
 *
 * <p><strong>Origins are configuration, not source</strong> (INSTRUCTIONS.md §Configuration over
 * Hardcoding). The default is the local development origin only; a deployment that serves the
 * console from a real hostname sets {@code GUARDIAN_ALLOWED_ORIGINS} and gets nothing by accident.
 */
@Configuration
public class CorsConfig {

  private final List<String> allowedOrigins;

  public CorsConfig(
      @Value("${guardian.web.allowed-origins:http://localhost:[*]}") List<String> allowedOrigins) {
    this.allowedOrigins = List.copyOf(allowedOrigins);
  }

  /**
   * The policy, applied to the API and the JWKS document.
   *
   * <p>Actuator is excluded. Health endpoints are read by probes, not by browsers, and an origin
   * able to read them from a signed-in user's session learns about the deployment for free.
   */
  @Bean
  CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();

    // Patterns rather than exact origins: `flutter run -d chrome` picks a fresh port on every
    // launch unless --web-port is pinned, so an exact list would have to be edited between runs
    // and would eventually be widened by someone in a hurry. The pattern still constrains scheme
    // and host — `http://localhost:[*]` matches no origin an attacker controls, because they
    // cannot serve from the developer's loopback.
    configuration.setAllowedOriginPatterns(allowedOrigins);

    configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));

    // Enumerated rather than "*", so a header this API does not read cannot be sent to it.
    // Idempotency-Key is here because retried writes carry it (API_STANDARDS.md), and
    // X-Client-Type because the server refuses an unknown client rather than defaulting
    // (AUTHENTICATION_API.md).
    //
    // PlatformElevation.HEADER is referenced rather than spelled out: a custom header the
    // server reads but the browser is not permitted to send fails as an opaque CORS error at
    // the preflight, with nothing in the server log to explain it. Naming the constant means
    // adding or renaming that header cannot leave this list behind.
    configuration.setAllowedHeaders(
        List.of(
            "Accept",
            "Authorization",
            "Content-Type",
            "Idempotency-Key",
            "X-Client-Type",
            PlatformElevation.HEADER));

    // See the class comment. Not a value to flip without reading it.
    configuration.setAllowCredentials(false);

    // One preflight per hour per method/path, instead of one before every request. The console is
    // grid-heavy and chatty; without this, half its requests are preflights.
    configuration.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/v1/**", configuration);
    source.registerCorsConfiguration("/.well-known/**", configuration);
    return source;
  }
}
