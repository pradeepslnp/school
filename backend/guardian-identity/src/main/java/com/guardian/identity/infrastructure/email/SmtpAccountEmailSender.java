package com.guardian.identity.infrastructure.email;

import com.guardian.identity.application.port.AccountEmailSender;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

/**
 * Sends account emails for real, over SMTP (ADR-0012).
 *
 * <p>The production counterpart of {@code LoggingAccountEmailSender}. Exactly one of the two is
 * registered: this one when {@code guardian.mail.enabled=true}, the logging one otherwise — so a
 * developer keeps the console-log codes by default, and turning the flag on starts delivering real
 * mail without touching a line of code. A production deployment must set it, because the logging
 * sender is additionally profile-gated out of {@code prod}: with neither bean the context fails to
 * start rather than silently not sending, which is the property worth preserving.
 *
 * <p>Plain-text {@link SimpleMailMessage} rather than HTML: these messages carry a six-digit code or
 * a single link, HTML would add a rendering surface and a spam signal for no gain, and plain text
 * renders identically in every client.
 *
 * <p><strong>Delivery failure is logged, not thrown.</strong> Every caller invokes this
 * <em>after</em> its transaction has committed (the code is already stored), so throwing here would
 * turn a mail-provider hiccup into a 500 on an endpoint whose work actually succeeded — and, on the
 * request-a-code endpoints, would break the anti-enumeration contract by making a failure visible
 * only for addresses that exist. The person retries; nothing is left half-written.
 */
@Component
@ConditionalOnProperty(name = "guardian.mail.enabled", havingValue = "true")
class SmtpAccountEmailSender implements AccountEmailSender {

  private static final Logger log = LoggerFactory.getLogger(SmtpAccountEmailSender.class);

  private final JavaMailSender mailSender;
  private final String from;
  private final String productName;
  private final String baseUrl;

  SmtpAccountEmailSender(
      JavaMailSender mailSender,
      @Value("${guardian.mail.from:no-reply@guardian.local}") String from,
      @Value("${guardian.mail.product-name:Guardian}") String productName,
      @Value("${guardian.admin.base-url:http://localhost:8081}") String baseUrl) {
    this.mailSender = mailSender;
    this.from = from;
    this.productName = productName;
    this.baseUrl = stripTrailingSlash(baseUrl);
  }

  @Override
  public void sendInvitation(String email, String firstName, String rawToken, Duration validFor) {
    send(
        email,
        "Set up your " + productName + " account",
        greeting(firstName)
            + "You have been invited to "
            + productName
            + ".\n\n"
            + "Set your password here:\n"
            + baseUrl
            + "/accept-invitation?token="
            + rawToken
            + "\n\nThis link is valid for "
            + validFor.toHours()
            + " hours.\n\n"
            + "If you were not expecting this invitation, you can ignore this email.\n");
  }

  @Override
  public void sendPasswordResetCode(String email, String firstName, String code, Duration validFor) {
    send(
        email,
        productName + " password reset code: " + code,
        greeting(firstName)
            + "Your password reset code is:\n\n    "
            + code
            + "\n\nIt is valid for "
            + validFor.toMinutes()
            + " minutes and can be used once.\n\n"
            + "If you did not ask to reset your password, ignore this email — your password has "
            + "not changed.\n");
  }

  @Override
  public void sendLoginCode(String email, String firstName, String code, Duration validFor) {
    send(
        email,
        productName + " sign-in code: " + code,
        greeting(firstName)
            + "Your sign-in code is:\n\n    "
            + code
            + "\n\nIt is valid for "
            + validFor.toMinutes()
            + " minutes and can be used once.\n\n"
            + "If you did not try to sign in, ignore this email and consider changing your "
            + "password.\n");
  }

  @Override
  public void sendPasswordChangedNotice(String email, String firstName) {
    send(
        email,
        "Your " + productName + " password was changed",
        greeting(firstName)
            + "Your password has just been changed, and you have been signed out on every other "
            + "device.\n\n"
            + "If this was not you, contact your administrator immediately.\n");
  }

  private void send(String to, String subject, String body) {
    SimpleMailMessage message = new SimpleMailMessage();
    message.setFrom(from);
    message.setTo(to);
    message.setSubject(subject);
    message.setText(body);

    try {
      mailSender.send(message);
      // The address is masked and the body — which carries the code — is never logged.
      log.info("Sent account email '{}' to {}", subject.split(":")[0], maskEmail(to));
    } catch (MailException e) {
      // Logged without the body, for the reasons in this class's documentation.
      log.error("Failed to send account email to {}: {}", maskEmail(to), e.getMessage());
    }
  }

  private static String greeting(String firstName) {
    return (firstName == null || firstName.isBlank() ? "Hello," : "Hello " + firstName + ",") + "\n\n";
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
