package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.AuthenticationFailedException;
import com.guardian.identity.application.command.StaffLoginCommand;
import com.guardian.identity.application.port.PasswordCredentialRepository;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.EmailMatch;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.PasswordCredential;
import com.guardian.identity.domain.User;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Signs a member of staff in with email and password (feature IAM-001).
 *
 * <p>Structurally this is {@link VerifyOtpUseCase} with a password in place of a one-time code: the
 * same pre-authentication bootstrap problem, the same reason failures are returned from inside the
 * transaction and thrown after it commits, and the same uniform refusal for an unknown, inactive,
 * or wrong-password account (BR-IAM-001). The two are kept as separate classes rather than unified
 * behind a shared "verify a secret" abstraction — see {@link PasswordCredential}'s class
 * documentation for why the credentials themselves are not unified, which is the same reasoning
 * applied one level up (ENGINEERING_PRINCIPLES.md §6).
 *
 * <h2>Why failures are returned rather than thrown</h2>
 *
 * <p>The verification body returns an {@link Outcome} and the exception is thrown <em>after</em>
 * the transaction commits. Recording a wrong attempt is a write, and throwing from inside the
 * transaction would roll it back — so the attempt counter would never advance, the lock would never
 * engage, and BR-IAM-011 would be enforced by a column nothing ever incremented.
 */
@Service
@BusinessRule("BR-IAM-011")
public class StaffLoginUseCase {

  private static final Logger log = LoggerFactory.getLogger(StaffLoginUseCase.class);

  private final PreAuthenticationDirectory directory;
  private final PasswordCredentialRepository passwordCredentials;
  private final UserRepository users;
  private final SecretHasher secretHasher;
  private final SessionFactory sessionFactory;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public StaffLoginUseCase(
      PreAuthenticationDirectory directory,
      PasswordCredentialRepository passwordCredentials,
      UserRepository users,
      SecretHasher secretHasher,
      SessionFactory sessionFactory,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.directory = directory;
    this.passwordCredentials = passwordCredentials;
    this.users = users;
    this.secretHasher = secretHasher;
    this.sessionFactory = sessionFactory;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  /**
   * @throws AuthenticationFailedException with a code chosen so an attacker learns nothing about
   *     whether the email address belongs to a real account — see {@link
   *     AuthenticationFailedException}
   */
  public IssuedSession execute(StaffLoginCommand command) {
    Instant now = Instant.now();

    String email = parseEmail(command.email());
    ClientType clientType = parseClientType(command.clientType());

    EmailMatch match = resolveSingleActiveUser(email);

    Outcome outcome =
        tenantScoped.execute(
            match.tenantId(),
            () -> verifyWithin(match, command.password(), clientType, command, now));

    // Thrown out here, after commit, so the failed-attempt write above survives.
    return switch (outcome) {
      case Outcome.Refused refused -> throw new AuthenticationFailedException(refused.code());
      case Outcome.Succeeded succeeded -> succeeded.session();
    };
  }

  private Outcome verifyWithin(
      EmailMatch match,
      String submittedPassword,
      ClientType clientType,
      StaffLoginCommand command,
      Instant now) {

    Optional<PasswordCredential> found = passwordCredentials.findByUserId(match.userId());
    if (found.isEmpty()) {
      // No password ever set for this account — a staff row provisioned but not yet given a
      // credential. Answered identically to a wrong password: distinguishing "not provisioned"
      // from "wrong password" would confirm the email address belongs to a real account.
      return Outcome.refused(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }

    PasswordCredential credential = found.get();

    if (credential.verdictAt(now) == PasswordCredential.Verdict.LOCKED) {
      return Outcome.refused(ErrorCode.AUTH_ACCOUNT_LOCKED);
    }

    if (!secretHasher.matches(submittedPassword, credential.secretHash())) {
      PasswordCredential afterFailure = credential.recordFailedAttempt(now);
      passwordCredentials.save(afterFailure);

      if (afterFailure.isLockedAt(now)) {
        // BR-IAM-011. Audited because a lockout on an admin-console account is the visible half
        // of a credential-stuffing attempt against the platform's highest-privilege human
        // surface, and support will be asked about it by the transport manager it locked out.
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

    passwordCredentials.save(credential.recordSuccessfulAttempt());

    Optional<User> user = users.findById(match.userId());
    if (user.isEmpty()) {
      // The pre-auth lookup found the row and the tenant-scoped read did not. That means RLS
      // context is wrong, not that the credential was bad — surfacing it as "invalid password"
      // would send an operator round a loop they cannot escape.
      log.error("User {} resolved pre-auth but is invisible under its own tenant", match.userId());
      return Outcome.refused(ErrorCode.INTERNAL_ERROR);
    }

    User signedIn = users.save(user.get().signedInAt(now));

    SessionFactory.Issued issued =
        sessionFactory.startSession(signedIn, match.tenantId(), clientType, null, now);

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
                    "PASSWORD",
                    // Masked, matching VerifyOtpUseCase's treatment of phone: an audit table is
                    // read by more people than the users table, and a full address there
                    // identifies a specific member of staff to anyone with audit access.
                    "email",
                    maskEmail(signedIn.email()),
                    "sourceIp",
                    nullToUnknown(command.sourceIp())))
            .build());

    return Outcome.succeeded(issued.response());
  }

  private EmailMatch resolveSingleActiveUser(String email) {
    List<EmailMatch> matches = directory.findByEmail(email);

    if (matches.size() > 1) {
      // BR-IAM-003: a person belongs to one organization. Refuse rather than pick a tenant at
      // random — see VerifyOtpUseCase.resolveSingleActiveUser for the identical reasoning.
      log.error(
          "Email resolves to {} users across tenants; refusing to guess (BR-IAM-003)",
          matches.size());
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    if (matches.isEmpty() || !matches.get(0).status().canAuthenticate()) {
      // One code for unknown, inactive, and locked-at-the-user-level alike.
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    return matches.get(0);
  }

  private static String parseEmail(String raw) {
    if (raw == null || raw.isBlank()) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_CREDENTIALS_INVALID);
    }
    return raw.trim();
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

  /** {@code first@example.com} → {@code f***@example.com}. Enough to recognise, not to read. */
  private static String maskEmail(String email) {
    if (email == null) {
      return "";
    }
    int at = email.indexOf('@');
    if (at <= 0) {
      return "***";
    }
    return email.charAt(0) + "***" + email.substring(at);
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
