package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.AuthenticationFailedException;
import com.guardian.identity.application.PasswordPolicy;
import com.guardian.identity.application.port.AccountTokenDirectory;
import com.guardian.identity.application.port.AccountTokenDirectory.TokenLocation;
import com.guardian.identity.application.port.AccountTokenRepository;
import com.guardian.identity.application.port.PasswordCredentialRepository;
import com.guardian.identity.application.port.SecretHasher;
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
 * Activates an invited administrative account: sets its first password and moves it {@code PENDING
 * → ACTIVE} (ADR-0012, feature IAM-009).
 *
 * <p>Public — the caller holds an invitation link and no session. Following {@code VerifyOtpUseCase}
 * in shape: the token is resolved across tenants by {@link AccountTokenDirectory} (the only way to
 * find the account from a token alone), then everything is done inside the resolved tenant under
 * RLS, and the refusal is thrown <em>after</em> the transaction so nothing is half-applied.
 *
 * <p>Clicking the link is itself the proof the invitee controls the email — there is no separate
 * verification step.
 */
@Service
@BusinessRule("BR-IAM-002")
public class AcceptInvitationUseCase {

  private static final Logger log = LoggerFactory.getLogger(AcceptInvitationUseCase.class);

  private final AccountTokenDirectory directory;
  private final AccountTokenRepository accountTokens;
  private final UserRepository users;
  private final PasswordCredentialRepository passwordCredentials;
  private final SecretHasher secretHasher;
  private final TokenHasher tokenHasher;
  private final PasswordPolicy passwordPolicy;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public AcceptInvitationUseCase(
      AccountTokenDirectory directory,
      AccountTokenRepository accountTokens,
      UserRepository users,
      PasswordCredentialRepository passwordCredentials,
      SecretHasher secretHasher,
      TokenHasher tokenHasher,
      PasswordPolicy passwordPolicy,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.directory = directory;
    this.accountTokens = accountTokens;
    this.users = users;
    this.passwordCredentials = passwordCredentials;
    this.secretHasher = secretHasher;
    this.tokenHasher = tokenHasher;
    this.passwordPolicy = passwordPolicy;
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
        directory.resolve(tokenHasher.hash(rawToken.trim()), TokenPurpose.INVITE);
    if (location.isEmpty()) {
      throw new AuthenticationFailedException(ErrorCode.AUTH_LINK_INVALID);
    }

    Outcome outcome =
        tenantScoped.execute(
            location.get().tenantId(), () -> acceptWithin(location.get(), newPassword, now));

    if (outcome instanceof Outcome.Refused refused) {
      throw new AuthenticationFailedException(refused.code());
    }
  }

  private Outcome acceptWithin(TokenLocation location, String newPassword, Instant now) {
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
      log.error("Invite token {} resolved pre-auth but its user is invisible under RLS", token.id());
      return Outcome.refused(ErrorCode.INTERNAL_ERROR);
    }

    User user = foundUser.get();
    if (user.status() != UserStatus.PENDING) {
      // Already activated (or deactivated). The invitation has done its job or is no longer valid;
      // reported as used so the page tells them to just sign in rather than retry.
      return Outcome.refused(ErrorCode.AUTH_LINK_ALREADY_USED);
    }

    // Only checked once the link is known good, so an expired link is not answered with a
    // password complaint. Throws straight out (rolling back), which is correct — nothing is set.
    passwordPolicy.validate(newPassword);

    passwordCredentials.save(
        PasswordCredential.issue(user.id(), secretHasher.hash(newPassword)));
    accountTokens.save(token.consume(now));
    User activated = users.save(user.withStatus(UserStatus.ACTIVE));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(location.tenantId())
            .actor(activated.id().value(), AuditRecord.ActorType.USER, null)
            .action("ACCOUNT_INVITATION_ACCEPTED")
            .subject("User", activated.id().value())
            .after(Map.<String, Object>of("method", "INVITE"))
            .build());

    return Outcome.succeeded();
  }

  /** Carried out of the transaction so the refusal is thrown only after it commits. */
  private sealed interface Outcome {

    record Succeeded() implements Outcome {}

    record Refused(ErrorCode code) implements Outcome {}

    static Outcome succeeded() {
      return new Succeeded();
    }

    static Outcome refused(ErrorCode code) {
      return new Refused(code);
    }
  }
}
