package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.AuthenticationFailedException;
import com.guardian.identity.application.PasswordPolicy;
import com.guardian.identity.application.port.AccountEmailSender;
import com.guardian.identity.application.port.PasswordCredentialRepository;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.EmailMatch;
import com.guardian.identity.application.port.ResetOtpCredentialRepository;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.PasswordCredential;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserStatus;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Completes a password reset: verifies the emailed code, sets the new password, and ends every
 * existing session (ADR-0012, feature IAM-010).
 *
 * <p>Shaped like {@code VerifyOtpUseCase}: the account is resolved by email across tenants (the
 * same bootstrap {@code StaffLoginUseCase} does), the code is checked under the resolved tenant
 * with the attempt counter advancing on a wrong guess, and the refusal is thrown <em>after</em> the
 * transaction so that failed-attempt write survives. Two things it does that sign-in does not: it
 * <strong>revokes all of the user's sessions</strong> (the old password may be compromised, so
 * everything it could have opened must close), and it emails a password-changed notice.
 *
 * <p>Which {@link ErrorCode} is returned is a security decision, matching the sign-in OTP path:
 * unknown email, inactive account, and wrong code all answer {@code AUTH_CREDENTIALS_INVALID} so
 * the endpoint cannot be used to enumerate accounts; expired, already-used, and locked are reported
 * distinctly because the person requested the code themselves and the client needs to tell them to
 * ask for a fresh one.
 */
@Service
@BusinessRule({"BR-IAM-007", "BR-IAM-011"})
public class ResetPasswordUseCase {

  private static final Logger log = LoggerFactory.getLogger(ResetPasswordUseCase.class);

  private static final String REVOKE_REASON = "PASSWORD_RESET";

  private final PreAuthenticationDirectory directory;
  private final ResetOtpCredentialRepository resetOtps;
  private final UserRepository users;
  private final PasswordCredentialRepository passwordCredentials;
  private final SessionRepository sessions;
  private final SecretHasher secretHasher;
  private final PasswordPolicy passwordPolicy;
  private final AccountEmailSender emailSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public ResetPasswordUseCase(
      PreAuthenticationDirectory directory,
      ResetOtpCredentialRepository resetOtps,
      UserRepository users,
      PasswordCredentialRepository passwordCredentials,
      SessionRepository sessions,
      SecretHasher secretHasher,
      PasswordPolicy passwordPolicy,
      AccountEmailSender emailSender,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.directory = directory;
    this.resetOtps = resetOtps;
    this.users = users;
    this.passwordCredentials = passwordCredentials;
    this.sessions = sessions;
    this.secretHasher = secretHasher;
    this.passwordPolicy = passwordPolicy;
    this.emailSender = emailSender;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  /**
   * @throws AuthenticationFailedException if the email/code pair is wrong, expired, used, or locked
   * @throws com.guardian.common.error.BusinessRuleViolationException if the new password is too
   *     weak
   */
  public void execute(String email, String otp, String newPassword) {
    Instant now = Instant.now();

    EmailMatch match = resolveSingleActiveUser(email);
    OtpCode submitted = parseOtp(otp);

    Outcome outcome =
        tenantScoped.execute(
            match.tenantId(), () -> resetWithin(match, submitted, newPassword, now));

    switch (outcome) {
      case Outcome.Refused refused -> throw new AuthenticationFailedException(refused.code());
      case Outcome.Succeeded succeeded ->
          // After commit: the new password and the killed sessions are durable, and only now is
          // the person told, so a rolled-back reset never sends a "your password changed" email.
          emailSender.sendPasswordChangedNotice(succeeded.email(), succeeded.firstName());
    }
  }

  private Outcome resetWithin(
      EmailMatch match, OtpCode submitted, String newPassword, Instant now) {
    Optional<OtpCredential> found = resetOtps.findLatest(match.userId());
    if (found.isEmpty()) {
      // Never requested a code. Same answer as a wrong code.
      return Outcome.refused(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }

    OtpCredential credential = found.get();
    switch (credential.verdictAt(now)) {
      case LOCKED -> {
        return Outcome.refused(ErrorCode.AUTH_ACCOUNT_LOCKED);
      }
      case EXPIRED -> {
        return Outcome.refused(ErrorCode.AUTH_OTP_EXPIRED);
      }
      case ALREADY_USED -> {
        return Outcome.refused(ErrorCode.AUTH_OTP_ALREADY_USED);
      }
      case ACCEPTABLE -> {
        // fall through to the hash comparison
      }
    }

    if (!secretHasher.matches(submitted.value(), credential.secretHash())) {
      OtpCredential afterFailure = credential.recordFailedAttempt(now);
      resetOtps.save(afterFailure);

      if (afterFailure.isLockedAt(now)) {
        auditPort.record(
            AuditRecord.builder()
                .tenantId(match.tenantId())
                .actor(match.userId().value(), AuditRecord.ActorType.SYSTEM, null)
                .action("AUTH_ACCOUNT_LOCKED")
                .subject("User", match.userId().value())
                .after(Map.<String, Object>of("context", "PASSWORD_RESET"))
                .build());
        return Outcome.refused(ErrorCode.AUTH_ACCOUNT_LOCKED);
      }
      return Outcome.refused(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }

    Optional<User> foundUser = users.findById(match.userId());
    if (foundUser.isEmpty()) {
      log.error("Reset code resolved pre-auth but user {} is invisible under RLS", match.userId());
      return Outcome.refused(ErrorCode.INTERNAL_ERROR);
    }
    User user = foundUser.get();
    if (user.status() != UserStatus.ACTIVE) {
      // Only an active account is issued a code (RequestPasswordResetUseCase gates on that); a
      // deactivated one arriving here must not be re-enabled by a reset.
      return Outcome.refused(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }

    passwordPolicy.validate(newPassword);

    String hash = secretHasher.hash(newPassword);
    PasswordCredential toSave =
        passwordCredentials
            .findByUserId(user.id())
            .map(existing -> existing.reissue(hash))
            .orElseGet(() -> PasswordCredential.issue(user.id(), hash));
    passwordCredentials.save(toSave);

    resetOtps.save(credential.consume(now));

    int revoked = sessions.revokeAllForUser(user.id().value(), REVOKE_REASON);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(match.tenantId())
            .actor(user.id().value(), AuditRecord.ActorType.USER, null)
            .action("AUTH_PASSWORD_RESET_COMPLETED")
            .subject("User", user.id().value())
            .after(Map.<String, Object>of("sessionsRevoked", revoked))
            .build());

    return Outcome.succeeded(user.email(), user.firstName());
  }

  private EmailMatch resolveSingleActiveUser(String email) {
    if (email == null || email.isBlank()) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    List<EmailMatch> matches = directory.findByEmail(email.trim());
    if (matches.size() > 1) {
      log.error(
          "Email resolves to {} users across tenants; refusing to guess (BR-IAM-003)",
          matches.size());
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    if (matches.isEmpty() || !matches.get(0).status().canAuthenticate()) {
      // One answer for unknown, inactive, and locked-at-the-user-level alike.
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    return matches.get(0);
  }

  private static OtpCode parseOtp(String raw) {
    try {
      return OtpCode.of(raw);
    } catch (IllegalArgumentException | NullPointerException e) {
      // Same failure as a wrong code — a distinct "that is not six digits" confirms the shape to
      // anything probing the endpoint.
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
  }

  /** Carried out of the transaction; success carries who to notify. */
  private sealed interface Outcome {

    record Succeeded(String email, String firstName) implements Outcome {}

    record Refused(ErrorCode code) implements Outcome {}

    static Outcome succeeded(String email, String firstName) {
      return new Succeeded(email, firstName);
    }

    static Outcome refused(ErrorCode code) {
      return new Refused(code);
    }
  }
}
