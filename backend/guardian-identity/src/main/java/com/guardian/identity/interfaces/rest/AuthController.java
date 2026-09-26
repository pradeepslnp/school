package com.guardian.identity.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.PublicEndpoint;
import com.guardian.common.security.SelfServiceEndpoint;
import com.guardian.identity.application.command.RequestOtpCommand;
import com.guardian.identity.application.command.StaffLoginCommand;
import com.guardian.identity.application.command.VerifyOtpCommand;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.application.usecase.AcceptInvitationUseCase;
import com.guardian.identity.application.usecase.EndMySessionUseCase;
import com.guardian.identity.application.usecase.ListMySessionsUseCase;
import com.guardian.identity.application.usecase.RefreshSessionUseCase;
import com.guardian.identity.application.usecase.RequestOtpUseCase;
import com.guardian.identity.application.usecase.RequestPasswordResetUseCase;
import com.guardian.identity.application.usecase.ResetPasswordUseCase;
import com.guardian.identity.application.usecase.StaffLoginUseCase;
import com.guardian.identity.application.usecase.VerifyOtpUseCase;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.interfaces.rest.dto.AcceptInvitationRequest;
import com.guardian.identity.interfaces.rest.dto.OtpRequestRequest;
import com.guardian.identity.interfaces.rest.dto.OtpRequestedResponse;
import com.guardian.identity.interfaces.rest.dto.OtpVerifyRequest;
import com.guardian.identity.interfaces.rest.dto.PasswordResetConfirmRequest;
import com.guardian.identity.interfaces.rest.dto.PasswordResetRequest;
import com.guardian.identity.interfaces.rest.dto.RefreshRequest;
import com.guardian.identity.interfaces.rest.dto.SessionResponse;
import com.guardian.identity.interfaces.rest.dto.SessionSummaryResponse;
import com.guardian.identity.interfaces.rest.dto.StaffLoginRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Authentication endpoints for every human client (features IAM-001, IAM-002, IAM-003, IAM-004).
 * See guardian-docs/04-api/AUTHENTICATION_API.md.
 *
 * <p>Two sign-in paths, one per credential kind: staff (admin console) authenticate by email and
 * password at {@link #login}; guardians (parent app) authenticate by phone and a one-time code at
 * {@link #requestOtp} and {@link #verifyOtp}. Neither client can reach the other's path — a
 * password submitted to {@code /otp/verify} is not a phone number and fails parsing, and an OTP
 * submitted to {@code /login} is not an email address for the same reason.
 *
 * <p>The sign-in and recovery methods carry {@link PublicEndpoint}: they are unauthenticated
 * because they are how authentication is obtained, and nothing else in the platform should ever be.
 * The session-management methods ({@link #mySessions}, {@link #logout}, {@link #revokeMySession})
 * carry {@link SelfServiceEndpoint} instead — authenticated, but acting only on the caller's own
 * identity, so no matrix permission applies. Either way the choice is explicit and the
 * deny-by-default architecture test (BR-IAM-002) fails the build for a method carrying neither.
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
  private final ListMySessionsUseCase listMySessions;
  private final EndMySessionUseCase endMySession;

  public AuthController(
      StaffLoginUseCase staffLogin,
      RequestOtpUseCase requestOtp,
      VerifyOtpUseCase verifyOtp,
      RefreshSessionUseCase refreshSession,
      AcceptInvitationUseCase acceptInvitation,
      RequestPasswordResetUseCase requestPasswordReset,
      ResetPasswordUseCase resetPassword,
      ListMySessionsUseCase listMySessions,
      EndMySessionUseCase endMySession) {
    this.staffLogin = staffLogin;
    this.requestOtp = requestOtp;
    this.verifyOtp = verifyOtp;
    this.refreshSession = refreshSession;
    this.acceptInvitation = acceptInvitation;
    this.requestPasswordReset = requestPasswordReset;
    this.resetPassword = resetPassword;
    this.listMySessions = listMySessions;
    this.endMySession = endMySession;
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

    requestOtp.execute(
        new RequestOtpCommand(request.phone(), sourceIp(httpRequest), request.clientType()));

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
   * Accepts an invitation: the invitee sets their password and their account becomes active
   * (IAM-009). Public because they hold a link, not a session — clicking the link is itself the
   * proof they control the email. A bad, expired, or used link fails with the specific {@code
   * AUTH_LINK_*} code so the page can tell them to request a fresh one (ADR-0012).
   */
  @PostMapping("/invitations/accept")
  @PublicEndpoint(reason = "an invitee has a link, not a session, until they set their password")
  public ResponseEntity<Void> acceptInvitation(
      @Valid @RequestBody AcceptInvitationRequest request) {
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
  @PublicEndpoint(
      reason = "a person who forgot their password cannot authenticate to ask for a reset")
  public ResponseEntity<Void> requestPasswordReset(
      @Valid @RequestBody PasswordResetRequest request) {
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
  @PublicEndpoint(
      reason = "the emailed code is the credential; the old password may be compromised")
  public ResponseEntity<Void> confirmPasswordReset(
      @Valid @RequestBody PasswordResetConfirmRequest request) {
    resetPassword.execute(request.email(), request.otp(), request.password());
    return ResponseEntity.noContent().build();
  }

  /**
   * The caller's own signed-in sessions, current one flagged (IAM-004). Authenticated but carries
   * no matrix permission — a person may always see their own sessions; reviewing someone else's is
   * a {@code PERM-SESSION-REVOKE} action on {@code /users/{id}/sessions}.
   */
  @GetMapping("/sessions")
  @SelfServiceEndpoint(reason = "a person may always list their own signed-in devices (IAM-004)")
  public List<SessionSummaryResponse> mySessions(CurrentActor actor) {
    return listMySessions.execute(actor.userId(), actor.sessionId()).stream()
        .map(SessionSummaryResponse::from)
        .toList();
  }

  /**
   * Ends the session this request was made from (IAM-004). The refresh token stops working at once;
   * the access token lasts out its ≤15-minute life (BR-IAM-007). The driver app also wipes its
   * encrypted local store on the client side (ADR-0008).
   */
  @PostMapping("/logout")
  @SelfServiceEndpoint(reason = "a person may always end the session they are calling from")
  public ResponseEntity<Void> logout(CurrentActor actor) {
    endMySession.execute(
        actor.sessionId(), actor.userId(), actor.role(), EndMySessionUseCase.Trigger.LOGOUT);
    return ResponseEntity.noContent().build();
  }

  /**
   * Signs a specific one of the caller's own devices out from the sessions list (IAM-004). A {@code
   * sessionId} that is not the caller's own answers {@code 404} — the endpoint does not confirm
   * another person's session id exists.
   */
  @DeleteMapping("/sessions/{sessionId}")
  @SelfServiceEndpoint(reason = "a person may always end one of their own sessions")
  public ResponseEntity<Void> revokeMySession(@PathVariable UUID sessionId, CurrentActor actor) {
    endMySession.execute(
        sessionId, actor.userId(), actor.role(), EndMySessionUseCase.Trigger.USER_REVOKED);
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
