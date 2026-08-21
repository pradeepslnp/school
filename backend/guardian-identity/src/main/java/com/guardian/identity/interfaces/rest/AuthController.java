package com.guardian.identity.interfaces.rest;

import com.guardian.common.security.PublicEndpoint;
import com.guardian.identity.application.command.RequestOtpCommand;
import com.guardian.identity.application.command.StaffLoginCommand;
import com.guardian.identity.application.command.VerifyOtpCommand;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.application.usecase.RefreshSessionUseCase;
import com.guardian.identity.application.usecase.RequestOtpUseCase;
import com.guardian.identity.application.usecase.StaffLoginUseCase;
import com.guardian.identity.application.usecase.VerifyOtpUseCase;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.interfaces.rest.dto.OtpRequestRequest;
import com.guardian.identity.interfaces.rest.dto.OtpRequestedResponse;
import com.guardian.identity.interfaces.rest.dto.OtpVerifyRequest;
import com.guardian.identity.interfaces.rest.dto.RefreshRequest;
import com.guardian.identity.interfaces.rest.dto.SessionResponse;
import com.guardian.identity.interfaces.rest.dto.StaffLoginRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Authentication endpoints for every human client (features IAM-001, IAM-002, IAM-003). See
 * guardian-docs/04-api/AUTHENTICATION_API.md.
 *
 * <p>Two sign-in paths, one per credential kind: staff (admin console) authenticate by email and
 * password at {@link #login}; guardians (parent app) authenticate by phone and a one-time code at
 * {@link #requestOtp} and {@link #verifyOtp}. Neither client can reach the other's path — a
 * password submitted to {@code /otp/verify} is not a phone number and fails parsing, and an OTP
 * submitted to {@code /login} is not an email address for the same reason.
 *
 * <p>Every method here carries {@link PublicEndpoint} rather than a permission. That is the
 * deny-by-default rule (BR-IAM-002) being satisfied by an explicit, reviewable decision — the
 * architecture test accepts either annotation and fails the build for a method carrying neither, so
 * an unprotected endpoint cannot ship by omission. These four are unauthenticated because they are
 * how authentication is obtained; nothing else in the platform should ever be.
 *
 * <p>This layer only translates. Every decision about who may sign in, what a failure means, and
 * what an attacker is allowed to learn lives in the use cases.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

  private final StaffLoginUseCase staffLogin;
  private final RequestOtpUseCase requestOtp;
  private final VerifyOtpUseCase verifyOtp;
  private final RefreshSessionUseCase refreshSession;

  public AuthController(
      StaffLoginUseCase staffLogin,
      RequestOtpUseCase requestOtp,
      VerifyOtpUseCase verifyOtp,
      RefreshSessionUseCase refreshSession) {
    this.staffLogin = staffLogin;
    this.requestOtp = requestOtp;
    this.verifyOtp = verifyOtp;
    this.refreshSession = refreshSession;
  }

  /**
   * Staff sign-in (IAM-001): the admin console's entry point, and the only client this endpoint
   * serves — guardians sign in by OTP, below.
   */
  @PostMapping("/login")
  @PublicEndpoint(reason = "how staff with no session obtain one (IAM-001)")
  public SessionResponse login(
      @Valid @RequestBody StaffLoginRequest request, HttpServletRequest httpRequest) {

    IssuedSession issued =
        staffLogin.execute(
            new StaffLoginCommand(
                request.email(), request.password(), request.clientType(), sourceIp(httpRequest)));

    return SessionResponse.from(issued);
  }

  /**
   * Sends a one-time code.
   *
   * <p><strong>Always {@code 202}</strong>, whether the number is registered, locked, or nonsense.
   * The use case returns normally in every case and this method has no failure branch to write —
   * which is the design, not an omission. An attacker able to tell a registered number from an
   * unregistered one holds a list of families at a named school.
   */
  @PostMapping("/otp/request")
  @PublicEndpoint(reason = "how a guardian with no session obtains one (IAM-002)")
  public ResponseEntity<OtpRequestedResponse> requestOtp(
      @Valid @RequestBody OtpRequestRequest request, HttpServletRequest httpRequest) {

    requestOtp.execute(new RequestOtpCommand(request.phone(), sourceIp(httpRequest)));

    return ResponseEntity.accepted()
        .body(OtpRequestedResponse.of(OtpCredential.LIFETIME.toSeconds()));
  }

  /**
   * Exchanges a code for a session. This is where the guardian's number becomes a signed-in user
   * and a stored session.
   */
  @PostMapping("/otp/verify")
  @PublicEndpoint(reason = "exchanges a one-time code for a session (IAM-002)")
  public SessionResponse verifyOtp(
      @Valid @RequestBody OtpVerifyRequest request, HttpServletRequest httpRequest) {

    IssuedSession issued =
        verifyOtp.execute(
            new VerifyOtpCommand(
                request.phone(),
                request.otp(),
                request.clientType(),
                request.deviceIdentifier(),
                sourceIp(httpRequest)));

    return SessionResponse.from(issued);
  }

  /**
   * Rotates a session (IAM-003).
   *
   * <p>Public because a caller whose access token has expired cannot present one — requiring
   * authentication here would make refresh useful only while it was unnecessary. The refresh token
   * is the credential.
   */
  @PostMapping("/refresh")
  @PublicEndpoint(reason = "the expired access token cannot authenticate its own replacement")
  public SessionResponse refresh(@Valid @RequestBody RefreshRequest request) {
    return SessionResponse.from(refreshSession.execute(request.refreshToken()));
  }

  /**
   * The caller's address, for the audit trail and per-source rate limiting.
   *
   * <p>Reads the socket address, not {@code X-Forwarded-For}. A client can set that header to
   * anything, so trusting it would let one host present a different "source" per request and walk
   * straight through a per-source limit. Behind a load balancer this must be replaced by Spring's
   * {@code ForwardedHeaderFilter} configured with the trusted proxy set — reading the header
   * directly is never the fix.
   */
  private static String sourceIp(HttpServletRequest request) {
    return request.getRemoteAddr();
  }
}
