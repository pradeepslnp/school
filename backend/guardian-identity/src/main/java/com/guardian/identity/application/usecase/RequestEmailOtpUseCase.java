package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.AccountEmailSender;
import com.guardian.identity.application.port.LoginOtpCredentialRepository;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.EmailMatch;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.User;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Emails a one-time sign-in code to an administrator (IAM-001, ADR-0012).
 *
 * <p>The admin console's second way in, alongside email + password: the operator types their email
 * and receives a 6-digit code. Both paths issue the same session; neither replaces the other, so an
 * organisation that prefers passwords keeps them and one that prefers codes never sets one.
 *
 * <p><strong>This method never reports failure</strong>, exactly as {@code RequestOtpUseCase} and
 * {@code RequestPasswordResetUseCase} do not: the response is identical whether the address belongs
 * to an account or not, so the endpoint cannot be used to discover who has one (OWASP
 * anti-enumeration). Every early return below is that contract, not a swallowed error.
 *
 * <h2>The development magic code</h2>
 *
 * <p>{@code guardian.auth.magic-otp} fixes the code so a developer can sign in without a mailbox —
 * the same mechanism the phone flow already uses. It is narrowed here by {@code
 * guardian.auth.magic-otp-emails}: when that list is set, only those addresses receive the fixed
 * code and <em>every other address gets a freshly generated one, actually delivered by email</em>.
 * That is what keeps a real operator's address on the real path even while the seeded demo accounts
 * stay convenient. Both properties are empty by default and are set only by the demo profile, so
 * production has no fixed code at all.
 */
@Service
@BusinessRule("BR-IAM-011")
public class RequestEmailOtpUseCase {

  /**
   * How long an emailed sign-in code stays valid.
   *
   * <p>Ten minutes, matching the emailed reset code rather than the five-minute SMS code: email can
   * sit in a queue or a spam filter, and a code that expires while it is still in transit is a
   * support ticket rather than a security gain.
   */
  public static final Duration CODE_LIFETIME = Duration.ofMinutes(10);

  private static final Logger log = LoggerFactory.getLogger(RequestEmailOtpUseCase.class);

  private final PreAuthenticationDirectory directory;
  private final LoginOtpCredentialRepository loginOtps;
  private final UserRepository users;
  private final SecretHasher secretHasher;
  private final AccountEmailSender emailSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;
  private final String magicOtp;
  private final Set<String> magicOtpEmails;

  public RequestEmailOtpUseCase(
      PreAuthenticationDirectory directory,
      LoginOtpCredentialRepository loginOtps,
      UserRepository users,
      SecretHasher secretHasher,
      AccountEmailSender emailSender,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped,
      @Value("${guardian.auth.magic-otp:}") String magicOtp,
      @Value("${guardian.auth.magic-otp-emails:}") String magicOtpEmails) {
    this.directory = directory;
    this.loginOtps = loginOtps;
    this.users = users;
    this.secretHasher = secretHasher;
    this.emailSender = emailSender;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
    this.magicOtp = magicOtp;
    this.magicOtpEmails =
        magicOtpEmails == null || magicOtpEmails.isBlank()
            ? Set.of()
            : Arrays.stream(magicOtpEmails.split(","))
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .map(value -> value.toLowerCase(Locale.ROOT))
                .collect(Collectors.toUnmodifiableSet());
  }

  public void execute(String email) {
    Instant now = Instant.now();

    if (email == null || email.isBlank()) {
      return;
    }
    String normalised = email.trim();

    List<EmailMatch> matches = directory.findByEmail(normalised);
    if (matches.isEmpty()) {
      log.debug("Sign-in code requested for an unregistered address");
      return;
    }
    if (matches.size() > 1) {
      // BR-IAM-003: an address belongs to one organization. More than one is a data defect;
      // refused rather than resolved by guessing, as in every other pre-auth path.
      log.error(
          "Email resolves to {} users across tenants; refusing to guess (BR-IAM-003)",
          matches.size());
      return;
    }

    EmailMatch match = matches.get(0);
    if (!match.status().canAuthenticate()) {
      // PENDING (invited, not yet activated), inactive, or locked — silent, as unregistered.
      log.debug("Sign-in code requested for a non-signable account");
      return;
    }

    // Issued under the resolved tenant; the plaintext is carried back out and sent only after
    // commit, so a rollback never leaves someone holding a code the database has no record of.
    Issued issued = tenantScoped.execute(match.tenantId(), () -> issueCode(match, normalised, now));
    if (issued == null) {
      return;
    }

    emailSender.sendLoginCode(issued.email(), issued.firstName(), issued.code(), CODE_LIFETIME);
  }

  private Issued issueCode(EmailMatch match, String requestedEmail, Instant now) {
    Optional<User> found = users.findById(match.userId());
    if (found.isEmpty()) {
      log.error("Email resolved pre-auth but user {} is invisible under RLS", match.userId());
      return null;
    }
    User user = found.get();

    // BR-IAM-011: a lock is not cleared by asking for a new code, or the attempt limit is
    // decorative — five guesses, request a fresh code, five more, forever.
    Optional<OtpCredential> latest = loginOtps.findLatest(user.id());
    if (latest.isPresent() && latest.get().isLockedAt(now)) {
      log.debug("Suppressed sign-in code for a locked credential");
      return null;
    }

    OtpCode code = usesMagicCode(requestedEmail) ? OtpCode.of(magicOtp) : OtpCode.generate();
    loginOtps.save(
        OtpCredential.issue(user.id(), secretHasher.hash(code.value()), now, CODE_LIFETIME));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(match.tenantId())
            .actor(user.id().value(), AuditRecord.ActorType.SYSTEM, null)
            .action("AUTH_EMAIL_OTP_REQUESTED")
            .subject("User", user.id().value())
            // The code is absent by construction: a one-time code in an audit record is a
            // credential in a table many people can read.
            .after(Map.<String, Object>of("expiresInSeconds", CODE_LIFETIME.toSeconds()))
            .build());

    return new Issued(code.value(), user.email(), user.firstName());
  }

  /**
   * Whether this address gets the fixed development code rather than a generated one.
   *
   * <p><strong>Opt-in by address, never blanket.</strong> Both a code and a matching entry in the
   * allow-list are required, so an empty list disables the shortcut for email sign-in entirely
   * rather than extending it to everyone. That asymmetry with the phone flow — where a configured
   * code applies to any number — is deliberate: a blanket rule here would mean a profile that sets
   * {@code magic-otp} for the parent app silently gives every administrator a guessable code, and
   * the admin console is the higher-privilege surface. Opting an address in has to be a decision
   * someone wrote down.
   *
   * <p>False in production regardless, because no code is configured there.
   */
  private boolean usesMagicCode(String email) {
    if (magicOtp == null || magicOtp.isBlank() || magicOtpEmails.isEmpty()) {
      return false;
    }
    return magicOtpEmails.contains(email.toLowerCase(Locale.ROOT));
  }

  /** The code to email, carried out of the transaction. */
  private record Issued(String code, String email, String firstName) {}
}
