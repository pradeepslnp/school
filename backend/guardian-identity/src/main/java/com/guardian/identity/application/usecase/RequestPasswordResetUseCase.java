package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.AccountEmailSender;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.EmailMatch;
import com.guardian.identity.application.port.ResetOtpCredentialRepository;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.User;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Starts a self-service password reset by emailing a one-time code (ADR-0012, feature IAM-010).
 *
 * <p>The admin console's reset is a 6-digit code the person types back, not a link — it works across
 * devices and email clients and fits an OTP-familiar market. The code reuses the sign-in OTP
 * machinery ({@link OtpCredential}: single use, 5-attempt lock, BR-IAM-011) but is stored under its
 * own {@code credential_type} so it can never be replayed as a sign-in, and lives longer (10
 * minutes) because email can lag and resetting a password is not a same-second action.
 *
 * <p><strong>This method never reports failure</strong>, for the same reason {@code
 * RequestOtpUseCase} does not: the response is identical whether the address belongs to an account
 * or not, so the endpoint cannot be used to discover who has one (OWASP anti-enumeration). Only an
 * {@code ACTIVE} account gets a code — a {@code PENDING} invitee has no password to reset and must
 * accept their invitation instead.
 */
@Service
@BusinessRule("BR-IAM-011")
public class RequestPasswordResetUseCase {

  /** How long an emailed reset code stays valid (ADR-0012). */
  public static final Duration CODE_LIFETIME = Duration.ofMinutes(10);

  private static final Logger log = LoggerFactory.getLogger(RequestPasswordResetUseCase.class);

  private final PreAuthenticationDirectory directory;
  private final ResetOtpCredentialRepository resetOtps;
  private final UserRepository users;
  private final SecretHasher secretHasher;
  private final AccountEmailSender emailSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;
  private final String magicOtp;

  public RequestPasswordResetUseCase(
      PreAuthenticationDirectory directory,
      ResetOtpCredentialRepository resetOtps,
      UserRepository users,
      SecretHasher secretHasher,
      AccountEmailSender emailSender,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped,
      @Value("${guardian.auth.magic-otp:}") String magicOtp) {
    this.directory = directory;
    this.resetOtps = resetOtps;
    this.users = users;
    this.secretHasher = secretHasher;
    this.emailSender = emailSender;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
    this.magicOtp = magicOtp;
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

    // Code issued under the resolved tenant; the plaintext is carried back out and emailed only
    // after commit — a rollback must never leave a person holding a code the DB never recorded.
    Issued issued = tenantScoped.execute(match.tenantId(), () -> issueCode(match, now));
    if (issued == null) {
      return;
    }

    emailSender.sendPasswordResetCode(issued.email(), issued.firstName(), issued.code(), CODE_LIFETIME);
  }

  private Issued issueCode(EmailMatch match, Instant now) {
    Optional<User> found = users.findById(match.userId());
    if (found.isEmpty()) {
      log.error("Email resolved pre-auth but user {} is invisible under RLS", match.userId());
      return null;
    }
    User user = found.get();

    // Suppress a fresh code while a lock is in force, exactly as RequestOtpUseCase does — otherwise
    // the attempt limit is decorative (guess five times, ask for a new code, repeat).
    Optional<OtpCredential> latest = resetOtps.findLatest(user.id());
    if (latest.isPresent() && latest.get().isLockedAt(now)) {
      log.debug("Suppressed reset code for a locked credential");
      return null;
    }

    OtpCode code = (magicOtp == null || magicOtp.isBlank()) ? OtpCode.generate() : OtpCode.of(magicOtp);
    resetOtps.save(
        OtpCredential.issue(user.id(), secretHasher.hash(code.value()), now, CODE_LIFETIME));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(match.tenantId())
            .actor(user.id().value(), AuditRecord.ActorType.USER, null)
            .action("AUTH_PASSWORD_RESET_REQUESTED")
            .subject("User", user.id().value())
            // The code is absent by construction — an OTP in an audit record is a credential in a
            // table many people can read.
            .after(Map.<String, Object>of("initiatedBy", "SELF_SERVICE"))
            .build());

    return new Issued(code.value(), user.email(), user.firstName());
  }

  /** The code to email, carried out of the transaction. */
  private record Issued(String code, String email, String firstName) {}
}
