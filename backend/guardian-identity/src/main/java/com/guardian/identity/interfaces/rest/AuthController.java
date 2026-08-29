package com.guardian.identity.interfaces.rest;

import com.guardian.common.security.PublicEndpoint;
import com.guardian.identity.application.command.RequestOtpCommand;
import com.guardian.identity.application.command.StaffLoginCommand;
import com.guardian.identity.application.command.VerifyEmailOtpCommand;
import com.guardian.identity.application.command.VerifyOtpCommand;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.application.usecase.AcceptInvitationUseCase;
import com.guardian.identity.application.usecase.RefreshSessionUseCase;
import com.guardian.identity.application.usecase.RequestEmailOtpUseCase;
import com.guardian.identity.application.usecase.RequestOtpUseCase;
import com.guardian.identity.application.usecase.RequestPasswordResetUseCase;
import com.guardian.identity.application.usecase.ResetPasswordUseCase;
import com.guardian.identity.application.usecase.StaffLoginUseCase;
import com.guardian.identity.application.usecase.VerifyEmailOtpUseCase;
import com.guardian.identity.application.usecase.VerifyOtpUseCase;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.interfaces.rest.dto.AcceptInvitationRequest;
import com.guardian.identity.interfaces.rest.dto.EmailOtpRequestRequest;
import com.guardian.identity.interfaces.rest.dto.EmailOtpVerifyRequest;
import com.guardian.identity.interfaces.rest.dto.OtpRequestRequest;
import com.guardian.identity.interfaces.rest.dto.OtpRequestedResponse;
import com.guardian.identity.interfaces.rest.dto.OtpVerifyRequest;
import com.guardian.identity.interfaces.rest.dto.PasswordResetConfirmRequest;
import com.guardian.identity.interfaces.rest.dto.PasswordResetRequest;
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
  private final AcceptInvitationUseCase acceptInvitation;
  private final RequestPasswordResetUseCase requestPasswordReset;
  private final ResetPasswordUseCase resetPassword;
  private final RequestEmailOtpUseCase requestEmailOtp;
  private final VerifyEmailOtpUseCase verifyEmailOtp;

  public AuthController(
      StaffLoginUseCase staffLogin,
      RequestOtpUseCase requestOtp,
      VerifyOtpUseCase verifyOtp,
      RefreshSessionUseCase refreshSession,
      AcceptInvitationUseCase acceptInvitation,
      RequestPasswordResetUseCase requestPasswordReset,
      ResetPasswordUseCase resetPassword,
      RequestEmailOtpUseCase requestEmailOtp,
      VerifyEmailOtpUseCase verifyEmailOtp) {
    this.staffLogin = staffLogin;
    this.requestOtp = requestOtp;
    this.verifyOtp = verifyOtp;
    this.refreshSession = refreshSession;
    this.acceptInvitation = acceptInvitation;
    this.requestPasswordReset = requestPasswordReset;
    this.resetPassword = resetPassword;
    this.requestEmailOtp = requestEmailOtp;
    this.verifyEmailOtp = verifyEmailOtp;
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
   * Emails a one-time sign-in code to an administrator (IAM-001) — the console's passwordless
   * option, alongside {@link #login}.
   *
   * <p><strong>Always {@code 202}</strong>, whether the address is registered, inactive, or unknown,
   * for the same reason {@code /otp/request} always accepts: a response that varies would let this
   * endpoint enumerate who has an account (ADR-0012).
   */
  @PostMapping("/email-otp/request")
  @PublicEndpoint(reason = "how an administrator with no session obtains a sign-in code (IAM-001)")
  public ResponseEntity<OtpRequestedResponse> requestEmailOtp(
      @Valid @RequestBody EmailOtpRequestRequest request) {

    requestEmailOtp.execute(request.email());

    return ResponseEntity.accepted()
        .body(OtpRequestedResponse.of(RequestEmailOtpUseCase.CODE_LIFETIME.toSeconds()));
  }

  /** Exchanges an emailed code for a session (IAM-001). */
  @PostMapping("/email-otp/verify")
  @PublicEndpoint(reason = "exchanges an emailed one-time code for a session (IAM-001)")
  public SessionResponse verifyEmailOtp(
      @Valid @RequestBody EmailOtpVerifyRequest request, HttpServletRequest httpRequest) {

    IssuedSession issued =
        verifyEmailOtp.execute(
            new VerifyEmailOtpCommand(
                request.email(),
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
   * Accepts an invitation: the invitee sets their password and their account becomes active
   * (IAM-009). Public because they hold a link, not a session — clicking the link is itself the
   * proof they control the email. A bad, expired, or used link fails with the specific {@code
   * AUTH_LINK_*} code so the page can tell them to request a fresh one (ADR-0012).
   */
  @PostMapping("/invitations/accept")
  @PublicEndpoint(reason = "an invitee has a link, not a session, until they set their password")
  public ResponseEntity<Void> acceptInvitation(@Valid @RequestBody AcceptInvitationRequest request) {
    acceptInvitation.execute(request.token(), request.password());
    return ResponseEntity.noContent().build();
  }

  /**
   * Requests a password-reset link.
   *
   * <p><strong>Always {@code 202}</strong>, whether or not the address belongs to an account — the
   * response cannot be used to discover who has one (OWASP). The use case has no failure branch to
   * report; see {@code RequestPasswordResetUseCase}.
   */
  @PostMapping("/password-reset/request")
  @PublicEndpoint(reason = "a person who forgot their password cannot authenticate to ask for a reset")
  public ResponseEntity<Void> requestPasswordReset(@Valid @RequestBody PasswordResetRequest request) {
    requestPasswordReset.execute(request.email());
    return ResponseEntity.accepted().build();
  }

  /**
   * Completes a password reset: verifies the emailed code, sets the new password, and ends every
   * existing session (IAM-010). Public because a person who forgot their password holds only the
   * code, not a session. A wrong/expired/used code fails like the sign-in OTP path so the endpoint
   * cannot be used to enumerate accounts (ADR-0012).
   */
  @PostMapping("/password-reset/confirm")
  @PublicEndpoint(reason = "the emailed code is the credential; the old password may be compromised")
  public ResponseEntity<Void> confirmPasswordReset(
      @Valid @RequestBody PasswordResetConfirmRequest request) {
    resetPassword.execute(request.email(), request.otp(), request.password());
    return ResponseEntity.noContent().build();
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
