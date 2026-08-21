package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.command.RequestOtpCommand;
import com.guardian.identity.application.port.OtpCredentialRepository;
import com.guardian.identity.application.port.OtpSender;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.PhoneMatch;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.PhoneNumber;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Issues a one-time code to a guardian (feature IAM-002).
 *
 * <p><strong>This method never reports failure.</strong> It returns normally whether the number is
 * registered, belongs to a locked account, is malformed, or matches nothing at all, and the
 * controller answers {@code 202} in every case. That is not defensive coding — it is the endpoint's
 * contract (guardian-docs/04-api/AUTHENTICATION_API.md). An attacker who can tell a registered
 * number from an unregistered one holds a list of families at a named school, which is the exact
 * capability the platform exists to protect.
 *
 * <p>Every early return below therefore looks like a swallowed error and is not one. The comments
 * mark them.
 */
@Service
@BusinessRule("BR-IAM-011")
public class RequestOtpUseCase {

  private static final Logger log = LoggerFactory.getLogger(RequestOtpUseCase.class);

  private final PreAuthenticationDirectory directory;
  private final OtpCredentialRepository otpCredentials;
  private final SecretHasher secretHasher;
  private final OtpSender otpSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;
  private final String magicOtp;

  public RequestOtpUseCase(
      PreAuthenticationDirectory directory,
      OtpCredentialRepository otpCredentials,
      SecretHasher secretHasher,
      OtpSender otpSender,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped,
      @Value("${guardian.auth.magic-otp:}") String magicOtp) {
    this.directory = directory;
    this.otpCredentials = otpCredentials;
    this.secretHasher = secretHasher;
    this.otpSender = otpSender;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
    this.magicOtp = magicOtp;
  }

  public void execute(RequestOtpCommand command) {
    Instant now = Instant.now();

    PhoneNumber phone;
    try {
      phone = PhoneNumber.of(command.phone());
    } catch (IllegalArgumentException e) {
      // Not an error path. A number too short to be one cannot match a user, and saying so
      // would distinguish "malformed" from "unregistered".
      log.debug("OTP requested for an unusable number");
      return;
    }

    List<PhoneMatch> matches = directory.findByPhone(phone);

    if (matches.isEmpty()) {
      // The ordinary unregistered case, and the one this endpoint exists to keep silent.
      log.debug("OTP requested for an unregistered number {}", phone.masked());
      return;
    }

    if (matches.size() > 1) {
      // BR-IAM-003: a person belongs to one organization. More than one match is a data
      // defect, and signing them into whichever row sorted first would be a cross-tenant
      // sign-in chosen at random. Refused, and loud in the log because somebody must fix it.
      log.error(
          "Phone {} resolves to {} users across tenants; refusing to guess (BR-IAM-003)",
          phone.masked(),
          matches.size());
      return;
    }

    PhoneMatch match = matches.get(0);
    if (!match.status().canAuthenticate()) {
      // Inactive or locked. Silent for the same reason as unregistered.
      log.debug("OTP requested for a non-signable account {}", phone.masked());
      return;
    }

    // The tenant is now known, so everything below runs under row-level security with it.
    // The code is carried back out of the transaction rather than sent inside it — see below.
    OtpCode code = tenantScoped.execute(match.tenantId(), () -> issueCode(match, now));

    if (code == null) {
      return;
    }

    // Sent after the transaction commits. Inside it, a rollback would leave the guardian
    // holding a code the database never recorded — an SMS that can only ever be rejected.
    otpSender.send(phone, code, OtpCredential.LIFETIME);
  }

  /** Returns the code to send, or null when no code should be issued. */
  private OtpCode issueCode(PhoneMatch match, Instant now) {
    Optional<OtpCredential> latest = otpCredentials.findLatest(match.userId());

    // BR-IAM-011: a lock is not cleared by asking for a new code. Without this check the
    // attempt limit is decorative — five guesses, request a fresh code, five more, forever.
    if (latest.isPresent() && latest.get().isLockedAt(now)) {
      log.debug("Suppressed OTP for a locked credential");
      return null;
    }

    OtpCode code =
        (magicOtp == null || magicOtp.isBlank()) ? OtpCode.generate() : OtpCode.of(magicOtp);
    otpCredentials.save(OtpCredential.issue(match.userId(), secretHasher.hash(code.value()), now));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(match.tenantId())
            .actor(match.userId().value(), AuditRecord.ActorType.SYSTEM, null)
            .action("AUTH_OTP_REQUESTED")
            .subject("User", match.userId().value())
            // The code is absent by construction: an OTP in an audit record is a credential
            // in a table many people can read.
            .after(Map.<String, Object>of("expiresInSeconds", OtpCredential.LIFETIME.toSeconds()))
            .build());

    return code;
  }
}
