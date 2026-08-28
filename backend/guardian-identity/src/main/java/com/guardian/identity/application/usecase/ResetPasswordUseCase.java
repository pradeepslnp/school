package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.AuthenticationFailedException;
import com.guardian.identity.application.PasswordPolicy;
import com.guardian.identity.application.port.AccountEmailSender;
import com.guardian.identity.application.port.AccountTokenDirectory;
import com.guardian.identity.application.port.AccountTokenDirectory.TokenLocation;
import com.guardian.identity.application.port.AccountTokenRepository;
import com.guardian.identity.application.port.PasswordCredentialRepository;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.SessionRepository;
import com.guardian.identity.application.port.TokenHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.AccountToken;
import com.guardian.identity.domain.PasswordCredential;
import com.guardian.identity.domain.TokenPurpose;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserStatus;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Completes a password reset: sets the new password and ends every existing session (ADR-0012,
 * feature IAM-010).
 *
 * <p>Same shape as {@link AcceptInvitationUseCase} — resolve the token across tenants, do the work
 * under the resolved tenant, throw the refusal after commit. Two things it does that acceptance does
 * not: it <strong>revokes all of the user's sessions</strong> (the old password may be compromised,
 * so everything it could have opened must close), and it emails a password-changed notice — the
 * out-of-band signal that catches a reset the account owner did not perform.
 */
@Service
@BusinessRule("BR-IAM-007")
public class ResetPasswordUseCase {

  private static final Logger log = LoggerFactory.getLogger(ResetPasswordUseCase.class);

  private static final String REVOKE_REASON = "PASSWORD_RESET";

  private final AccountTokenDirectory directory;
  private final AccountTokenRepository accountTokens;
  private final UserRepository users;
  private final PasswordCredentialRepository passwordCredentials;
  private final SessionRepository sessions;
  private final SecretHasher secretHasher;
  private final TokenHasher tokenHasher;
  private final PasswordPolicy passwordPolicy;
  private final AccountEmailSender emailSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public ResetPasswordUseCase(
      AccountTokenDirectory directory,
      AccountTokenRepository accountTokens,
      UserRepository users,
      PasswordCredentialRepository passwordCredentials,
      SessionRepository sessions,
      SecretHasher secretHasher,
      TokenHasher tokenHasher,
      PasswordPolicy passwordPolicy,
      AccountEmailSender emailSender,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.directory = directory;
    this.accountTokens = accountTokens;
    this.users = users;
    this.passwordCredentials = passwordCredentials;
    this.sessions = sessions;
    this.secretHasher = secretHasher;
    this.tokenHasher = tokenHasher;
    this.passwordPolicy = passwordPolicy;
    this.emailSender = emailSender;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  /**
   * @throws AuthenticationFailedException if the link is unknown, expired, or already used
   * @throws com.guardian.common.error.BusinessRuleViolationException if the password is too weak
   */
  public void execute(String rawToken, String newPassword) {
    Instant now = Instant.now();

    if (rawToken == null || rawToken.isBlank()) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_LINK_INVALID);
    }

    Optional<TokenLocation> location =
        directory.resolve(tokenHasher.hash(rawToken.trim()), TokenPurpose.RESET);
    if (location.isEmpty()) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_LINK_INVALID);
    }

    Outcome outcome =
        tenantScoped.execute(
            location.get().tenantId(), () -> resetWithin(location.get(), newPassword, now));

    switch (outcome) {
      case Outcome.Refused refused -> throw new AuthenticationFailedException(refused.code());
      case Outcome.Succeeded succeeded ->
          // After commit: the new password and the killed sessions are durable, and only now is
          // the person told, so a rolled-back reset never sends a "your password changed" email.
          emailSender.sendPasswordChangedNotice(succeeded.email(), succeeded.firstName());
    }
  }

  private Outcome resetWithin(TokenLocation location, String newPassword, Instant now) {
    Optional<AccountToken> found = accountTokens.findById(location.credentialId());
    if (found.isEmpty()) {
      return Outcome.refused(ErrorCode.AUTH_LINK_INVALID);
    }

    AccountToken token = found.get();
    switch (token.verdictAt(now)) {
      case EXPIRED -> {
        return Outcome.refused(ErrorCode.AUTH_LINK_EXPIRED);
      }
      case ALREADY_USED -> {
        return Outcome.refused(ErrorCode.AUTH_LINK_ALREADY_USED);
      }
      case ACCEPTABLE -> {
        // fall through
      }
    }

    Optional<User> foundUser = users.findById(location.userId());
    if (foundUser.isEmpty()) {
      log.error("Reset token {} resolved pre-auth but its user is invisible under RLS", token.id());
      return Outcome.refused(ErrorCode.INTERNAL_ERROR);
    }

    User user = foundUser.get();
    if (user.status() != UserStatus.ACTIVE) {
      // A reset link only reaches an active account (RequestPasswordResetUseCase gates on that);
      // a deactivated account arriving here should not be re-enabled by a reset.
      return Outcome.refused(ErrorCode.AUTH_LINK_INVALID);
    }

    passwordPolicy.validate(newPassword);

    String hash = secretHasher.hash(newPassword);
    PasswordCredential toSave =
        passwordCredentials
            .findByUserId(user.id())
            .map(existing -> existing.reissue(hash))
            .orElseGet(() -> PasswordCredential.issue(user.id(), hash));
    passwordCredentials.save(toSave);

    accountTokens.save(token.consume(now));

    int revoked = sessions.revokeAllForUser(user.id().value(), REVOKE_REASON);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(location.tenantId())
            .actor(user.id().value(), AuditRecord.ActorType.USER, null)
            .action("AUTH_PASSWORD_RESET_COMPLETED")
            .subject("User", user.id().value())
            .after(Map.<String, Object>of("sessionsRevoked", revoked))
            .build());

    return Outcome.succeeded(user.email(), user.firstName());
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
