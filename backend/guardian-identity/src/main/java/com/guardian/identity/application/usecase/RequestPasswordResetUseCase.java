package com.guardian.identity.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.AccountEmailSender;
import com.guardian.identity.application.port.AccountTokenRepository;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.EmailMatch;
import com.guardian.identity.application.port.TokenHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.AccountToken;
import com.guardian.identity.domain.LinkToken;
import com.guardian.identity.domain.TokenPurpose;
import com.guardian.identity.domain.User;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Starts a self-service password reset by emailing a link (ADR-0012, feature IAM-010).
 *
 * <p><strong>This method never reports failure</strong>, for the same reason {@code
 * RequestOtpUseCase} does not: the response is identical whether the address belongs to an account
 * or not, so the endpoint cannot be used to discover who has one (OWASP anti-enumeration). Every
 * early return below is that contract, not a swallowed error.
 *
 * <p>Only an {@code ACTIVE} account gets a link. A {@code PENDING} invitee has no password to reset
 * and must accept their invitation instead; an inactive or locked account is silent like an unknown
 * one.
 */
@Service
public class RequestPasswordResetUseCase {

  private static final Logger log = LoggerFactory.getLogger(RequestPasswordResetUseCase.class);

  private final PreAuthenticationDirectory directory;
  private final AccountTokenRepository accountTokens;
  private final UserRepository users;
  private final TokenHasher tokenHasher;
  private final AccountEmailSender emailSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public RequestPasswordResetUseCase(
      PreAuthenticationDirectory directory,
      AccountTokenRepository accountTokens,
      UserRepository users,
      TokenHasher tokenHasher,
      AccountEmailSender emailSender,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.directory = directory;
    this.accountTokens = accountTokens;
    this.users = users;
    this.tokenHasher = tokenHasher;
    this.emailSender = emailSender;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public void execute(String email) {
    Instant now = Instant.now();

    if (email == null || email.isBlank()) {
      return;
    }

    List<EmailMatch> matches = directory.findByEmail(email.trim());
    if (matches.isEmpty()) {
      log.debug("Password reset requested for an unregistered address");
      return;
    }
    if (matches.size() > 1) {
      // BR-IAM-003: an address belongs to one organization. More than one is a data defect;
      // refused rather than resolved by guessing, as in the OTP path.
      log.error("Email resolves to {} users across tenants; refusing to guess (BR-IAM-003)", matches.size());
      return;
    }

    EmailMatch match = matches.get(0);
    if (!match.status().canAuthenticate()) {
      // PENDING (no password yet), inactive, or locked — silent, same as unregistered.
      log.debug("Password reset requested for a non-signable account");
      return;
    }

    // Token issued under the resolved tenant; the raw value is carried back out and sent only
    // after commit — a rollback must never leave a person holding a link the DB never recorded.
    Issued issued = tenantScoped.execute(match.tenantId(), () -> issueReset(match, now));
    if (issued == null) {
      return;
    }

    emailSender.sendPasswordReset(
        issued.email(), issued.firstName(), issued.rawToken(), TokenPurpose.RESET.lifetime());
  }

  private Issued issueReset(EmailMatch match, Instant now) {
    Optional<User> found = users.findById(match.userId());
    if (found.isEmpty()) {
      log.error("Email resolved pre-auth but user {} is invisible under RLS", match.userId());
      return null;
    }
    User user = found.get();

    LinkToken raw = LinkToken.generate();
    accountTokens.save(
        AccountToken.issue(user.id(), TokenPurpose.RESET, tokenHasher.hash(raw.value()), now));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(match.tenantId())
            .actor(user.id().value(), AuditRecord.ActorType.USER, null)
            .action("AUTH_PASSWORD_RESET_REQUESTED")
            .subject("User", user.id().value())
            .after(Map.<String, Object>of("initiatedBy", "SELF_SERVICE"))
            .build());

    return new Issued(raw.value(), user.email(), user.firstName());
  }

  /** The link to send, carried out of the transaction. */
  private record Issued(String rawToken, String email, String firstName) {}
}
