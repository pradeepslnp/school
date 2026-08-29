package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.AuthenticationFailedException;
import com.guardian.identity.application.command.VerifyEmailOtpCommand;
import com.guardian.identity.application.port.LoginOtpCredentialRepository;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.EmailMatch;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.User;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Exchanges an emailed one-time code for a session (IAM-001, ADR-0012).
 *
 * <p>The email counterpart of {@code VerifyOtpUseCase}, and deliberately the same shape: resolve the
 * account across tenants by its identifier, check the code under the resolved tenant with the
 * attempt counter advancing on a wrong guess, and throw the refusal <em>after</em> the transaction
 * so that failed-attempt write survives. Getting that ordering wrong is invisible — the endpoint
 * still answers "invalid" — and only an attacker with unlimited guesses ever notices (BR-IAM-011).
 *
 * <p>Which {@link ErrorCode} is returned is a security decision, matching the phone path: unknown
 * address, inactive account and wrong code all answer {@code AUTH_CREDENTIALS_INVALID}; expired,
 * already-used and locked are reported distinctly, because the person asked for the code themselves
 * and the client needs to send them for a fresh one rather than leave them retyping a dead code.
 */
@Service
@BusinessRule("BR-IAM-011")
public class VerifyEmailOtpUseCase {

  private static final Logger log = LoggerFactory.getLogger(VerifyEmailOtpUseCase.class);

  private final PreAuthenticationDirectory directory;
  private final LoginOtpCredentialRepository loginOtps;
  private final UserRepository users;
  private final SecretHasher secretHasher;
  private final SessionFactory sessionFactory;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public VerifyEmailOtpUseCase(
      PreAuthenticationDirectory directory,
      LoginOtpCredentialRepository loginOtps,
      UserRepository users,
      SecretHasher secretHasher,
      SessionFactory sessionFactory,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.directory = directory;
    this.loginOtps = loginOtps;
    this.users = users;
    this.secretHasher = secretHasher;
    this.sessionFactory = sessionFactory;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  /**
   * @throws AuthenticationFailedException with a code chosen so an attacker learns nothing about
   *     whether the address exists — see {@link AuthenticationFailedException}
   */
  public IssuedSession execute(VerifyEmailOtpCommand command) {
    Instant now = Instant.now();

    ClientType clientType = parseClientType(command.clientType());
    OtpCode submitted = parseOtp(command.otp());
    EmailMatch match = resolveSingleActiveUser(command.email());

    Outcome outcome =
        tenantScoped.execute(
            match.tenantId(), () -> verifyWithin(match, submitted, clientType, command, now));

    // Thrown out here, after commit, so the failed-attempt write above survives.
    return switch (outcome) {
      case Outcome.Refused refused -> throw new AuthenticationFailedException(refused.code());
      case Outcome.Succeeded succeeded -> succeeded.session();
    };
  }

  private Outcome verifyWithin(
      EmailMatch match,
      OtpCode submitted,
      ClientType clientType,
      VerifyEmailOtpCommand command,
      Instant now) {

    Optional<OtpCredential> found = loginOtps.findLatest(match.userId());
    if (found.isEmpty()) {
      // Never asked for a code. Same answer as a wrong one.
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
      loginOtps.save(afterFailure);

      if (afterFailure.isLockedAt(now)) {
        auditPort.record(
            AuditRecord.builder()
                .tenantId(match.tenantId())
                .actor(match.userId().value(), AuditRecord.ActorType.SYSTEM, null)
                .action("AUTH_ACCOUNT_LOCKED")
                .subject("User", match.userId().value())
                .after(
                    Map.<String, Object>of(
                        "context", "EMAIL_OTP",
                        "failedAttempts", afterFailure.failedAttempts(),
                        "sourceIp", nullToUnknown(command.sourceIp())))
                .build());
        return Outcome.refused(ErrorCode.AUTH_ACCOUNT_LOCKED);
      }
      return Outcome.refused(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }

    loginOtps.save(credential.consume(now));

    Optional<User> foundUser = users.findById(match.userId());
    if (foundUser.isEmpty()) {
      log.error("User {} resolved pre-auth but is invisible under its own tenant", match.userId());
      return Outcome.refused(ErrorCode.INTERNAL_ERROR);
    }

    User signedIn = users.save(foundUser.get().signedInAt(now));

    SessionFactory.Issued issued =
        sessionFactory.startSession(
            signedIn, match.tenantId(), clientType, command.deviceIdentifier(), now);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(match.tenantId())
            .actor(signedIn.id().value(), AuditRecord.ActorType.USER, null)
            .action("AUTH_SIGNED_IN")
            .subject("Session", issued.session().id().value())
            .after(
                Map.<String, Object>of(
                    "clientType", clientType.name(),
                    "method", "EMAIL_OTP",
                    "sourceIp", nullToUnknown(command.sourceIp())))
            .build());

    return Outcome.succeeded(issued.response());
  }

  private EmailMatch resolveSingleActiveUser(String email) {
    if (email == null || email.isBlank()) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    List<EmailMatch> matches = directory.findByEmail(email.trim());

    if (matches.size() > 1) {
      // BR-IAM-003, as in the phone path: refuse rather than pick a tenant at random.
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
      // Deliberately the same failure as a wrong code — a distinct "that is not six digits"
      // confirms the code's shape to anything probing the endpoint.
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
  }

  private static ClientType parseClientType(String raw) {
    try {
      return ClientType.fromWire(raw);
    } catch (IllegalArgumentException | NullPointerException e) {
      // A caller mistake, not a credential guess, and it carries no information about any
      // account — so it is reported as what it is.
      throw new AuthenticationFailedException(ErrorCode.VALIDATION_INVALID_FORMAT);
    }
  }

  private static String nullToUnknown(String value) {
    return value == null || value.isBlank() ? "unknown" : value;
  }

  /** The result of a verification attempt, carried out of the transaction before it is thrown. */
  private sealed interface Outcome {

    record Succeeded(IssuedSession session) implements Outcome {}

    record Refused(ErrorCode code) implements Outcome {}

    static Outcome succeeded(IssuedSession session) {
      return new Succeeded(session);
    }

    static Outcome refused(ErrorCode code) {
      return new Refused(code);
    }
  }
}
