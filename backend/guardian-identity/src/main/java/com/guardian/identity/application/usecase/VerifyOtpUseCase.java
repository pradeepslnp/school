package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.AmbiguousPhoneResolver;
import com.guardian.identity.application.AuthenticationFailedException;
import com.guardian.identity.application.command.VerifyOtpCommand;
import com.guardian.identity.application.port.OtpCredentialRepository;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.PhoneMatch;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.User;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Exchanges a one-time code for a session (feature IAM-002).
 *
 * <p>This is the point at which the mobile number the guardian typed becomes a durable fact: the
 * matched {@code users} row records {@code last_login_at}, and a {@code sessions} row is written
 * against it. The number itself is not created here — {@code users} rows are created by the school
 * (see {@link com.guardian.identity.domain.User}), and an unknown number is refused rather than
 * registered.
 *
 * <h2>Why failures are returned rather than thrown</h2>
 *
 * <p>The verification body returns an {@link Outcome} and the exception is thrown <em>after</em>
 * the transaction commits. That is not indirection for its own sake. Recording a wrong attempt is a
 * write, and throwing from inside the transaction would roll it back — so the attempt counter would
 * never advance, the lock would never engage, and BR-IAM-011 would be enforced by a column nothing
 * ever incremented. The bug leaves no trace: the endpoint still answers "invalid", and only an
 * attacker with unlimited guesses ever notices.
 */
@Service
@BusinessRule("BR-IAM-011")
public class VerifyOtpUseCase {

  private static final Logger log = LoggerFactory.getLogger(VerifyOtpUseCase.class);

  private final PreAuthenticationDirectory directory;
  private final OtpCredentialRepository otpCredentials;
  private final UserRepository users;
  private final SecretHasher secretHasher;
  private final SessionFactory sessionFactory;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;
  private final AmbiguousPhoneResolver ambiguousPhones;

  public VerifyOtpUseCase(
      PreAuthenticationDirectory directory,
      OtpCredentialRepository otpCredentials,
      UserRepository users,
      SecretHasher secretHasher,
      SessionFactory sessionFactory,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped,
      AmbiguousPhoneResolver ambiguousPhones) {
    this.directory = directory;
    this.otpCredentials = otpCredentials;
    this.users = users;
    this.secretHasher = secretHasher;
    this.sessionFactory = sessionFactory;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
    this.ambiguousPhones = ambiguousPhones;
  }

  /**
   * @throws AuthenticationFailedException with a code chosen so an attacker learns nothing about
   *     whether the number exists — see {@link AuthenticationFailedException}
   */
  public IssuedSession execute(VerifyOtpCommand command) {
    Instant now = Instant.now();

    PhoneNumber phone = parsePhone(command.phone());
    ClientType clientType = parseClientType(command.clientType());
    OtpCode submitted = parseOtp(command.otp());

    PhoneMatch match = resolveSingleActiveUser(phone, clientType);

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
      PhoneMatch match,
      OtpCode submitted,
      ClientType clientType,
      VerifyOtpCommand command,
      Instant now) {

    Optional<OtpCredential> found = otpCredentials.findLatest(match.userId());
    if (found.isEmpty()) {
      // Never asked for a code, or asked so long ago the row was pruned. Same answer as a
      // wrong code.
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
      otpCredentials.save(afterFailure);

      if (afterFailure.isLockedAt(now)) {
        // BR-IAM-011. Audited because a lockout is the visible half of a credential-stuffing
        // attempt, and support will be asked about it by the parent it locked out.
        auditPort.record(
            AuditRecord.builder()
                .tenantId(match.tenantId())
                .actor(match.userId().value(), AuditRecord.ActorType.SYSTEM, null)
                .action("AUTH_ACCOUNT_LOCKED")
                .subject("User", match.userId().value())
                .after(
                    Map.<String, Object>of(
                        "failedAttempts", afterFailure.failedAttempts(),
                        "sourceIp", nullToUnknown(command.sourceIp())))
                .build());
        return Outcome.refused(ErrorCode.AUTH_ACCOUNT_LOCKED);
      }
      return Outcome.refused(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }

    otpCredentials.save(credential.consume(now));

    Optional<User> user = users.findById(match.userId());
    if (user.isEmpty()) {
      // The pre-auth lookup found the row and the tenant-scoped read did not. That means RLS
      // context is wrong, not that the credential was bad — surfacing it as "invalid code"
      // would send a parent round a loop they cannot escape.
      log.error("User {} resolved pre-auth but is invisible under its own tenant", match.userId());
      return Outcome.refused(ErrorCode.INTERNAL_ERROR);
    }

    // The sign-in that the guardian's number is recorded against.
    User signedIn = users.save(user.get().signedInAt(now));

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
                    "clientType",
                    clientType.name(),
                    "method",
                    "OTP",
                    // Masked. A full number in the audit table identifies a family, and audit
                    // records are readable by more people than the users table.
                    "phone",
                    signedIn.phone() == null ? "" : signedIn.phone().masked(),
                    "sourceIp",
                    nullToUnknown(command.sourceIp())))
            .build());

    return Outcome.succeeded(issued.response());
  }

  private PhoneMatch resolveSingleActiveUser(PhoneNumber phone, ClientType clientType) {
    List<PhoneMatch> matches = directory.findByPhone(phone);

    if (matches.size() > 1) {
      // BR-IAM-003, as in RequestOtpUseCase: refuse rather than pick a tenant at random — unless
      // this is a magic-OTP build, where the client signing in picks (demo only).
      Optional<PhoneMatch> chosen = ambiguousPhones.resolve(phone, matches, clientType);
      if (chosen.isPresent()) {
        return chosen.get();
      }
      log.error(
          "Phone {} resolves to {} users across tenants; refusing to guess (BR-IAM-003)",
          phone.masked(),
          matches.size());
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    if (matches.isEmpty() || !matches.get(0).status().canAuthenticate()) {
      // One code for unknown, inactive, and locked-at-the-user-level alike.
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    return matches.get(0);
  }

  private static PhoneNumber parsePhone(String raw) {
    try {
      return PhoneNumber.of(raw);
    } catch (IllegalArgumentException | NullPointerException e) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
  }

  private static OtpCode parseOtp(String raw) {
    try {
      return OtpCode.of(raw);
    } catch (IllegalArgumentException | NullPointerException e) {
      // Deliberately the same failure as a wrong code. A distinct "that is not six digits"
      // confirms the code's shape to anything probing the endpoint.
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
  }

  private static ClientType parseClientType(String raw) {
    try {
      return ClientType.fromWire(raw);
    } catch (IllegalArgumentException | NullPointerException e) {
      // Unlike the others this is a caller mistake, not a credential guess, and it carries no
      // information about any account — so it is reported as what it is.
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
