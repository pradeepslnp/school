package com.guardian.identity.infrastructure.email;

import com.guardian.identity.application.port.AccountEmailSender;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Writes account-lifecycle emails to the application log instead of sending them.
 *
 * <p>The exact counterpart of {@code LoggingOtpSender}, and contained the same way: it lets the
 * invite and reset flows be exercised end to end with no email provider and no credentials, and it
 * is gated by {@code @Profile("!prod & !production")} rather than an {@code if}, so a production
 * deployment with no real {@link AccountEmailSender} on the classpath <strong>fails to start</strong>
 * rather than silently not sending. The raw link — which carries the token — is printed here because
 * reading it is the entire purpose in development; the recipient's email is masked, because the pair
 * of a working link and a named address is what would matter if this log were ever read in anger.
 *
 * <p>Replacing this is what makes delivery real: an SMTP/provider adapter implements the same port
 * and this class is not touched (ADR-0012, ADR-0005 {@code EmailChannel}).
 */
@Component
@Profile("!prod & !production")
@ConditionalOnProperty(name = "guardian.mail.enabled", havingValue = "false", matchIfMissing = true)
class LoggingAccountEmailSender implements AccountEmailSender {

  private static final Logger log = LoggerFactory.getLogger(LoggingAccountEmailSender.class);

  private final String baseUrl;

  LoggingAccountEmailSender(@Value("${guardian.admin.base-url:http://localhost:8081}") String baseUrl) {
    this.baseUrl = stripTrailingSlash(baseUrl);
  }

  @Override
  public void sendInvitation(String email, String firstName, String rawToken, Duration validFor) {
    log.warn(
        "DEVELOPMENT invitation for {} — set-password link: {}/accept-invitation?token={} (valid {}h)."
            + " No email was sent.",
        maskEmail(email),
        baseUrl,
        rawToken,
        validFor.toHours());
  }

  @Override
  public void sendPasswordResetCode(String email, String firstName, String code, Duration validFor) {
    // The code is printed because reading it is the entire purpose in development; the address is
    // masked. Same containment as the OTP sign-in code (LoggingOtpSender).
    log.warn(
        "DEVELOPMENT password reset for {} — reset code is {} (valid {}m). No email was sent.",
        maskEmail(email),
        code,
        validFor.toMinutes());
  }

  @Override
  public void sendLoginCode(String email, String firstName, String code, Duration validFor) {
    // The code is printed because reading it is the entire purpose in development; the address is
    // masked. Same containment as LoggingOtpSender.
    log.warn(
        "DEVELOPMENT sign-in code for {} is {} (valid {}m). No email was sent.",
        maskEmail(email),
        code,
        validFor.toMinutes());
  }

  @Override
  public void sendPasswordChangedNotice(String email, String firstName) {
    log.warn(
        "DEVELOPMENT password-changed notice for {}. No email was sent.", maskEmail(email));
  }

  /** {@code first@example.com} → {@code f***@example.com}, matching the identity use cases. */
  private static String maskEmail(String email) {
    if (email == null) {
      return "***";
    }
    int at = email.indexOf('@');
    if (at <= 0) {
      return "***";
    }
    return email.charAt(0) + "***" + email.substring(at);
  }

  private static String stripTrailingSlash(String url) {
    return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
  }
}
