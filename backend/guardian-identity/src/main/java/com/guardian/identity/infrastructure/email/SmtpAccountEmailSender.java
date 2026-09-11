package com.guardian.identity.infrastructure.email;

import com.guardian.identity.application.port.AccountEmailSender;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

/**
 * Sends the account-lifecycle emails over SMTP (ADR-0014).
 *
 * <p>The real counterpart of {@link LoggingAccountEmailSender}, implementing the same port without
 * touching it. Registered only when {@code spring.mail.host} is set — which is also the exact
 * condition under which Spring Boot creates the {@link JavaMailSender} this depends on — and marked
 * {@link Primary} so that in a development environment where both beans exist (a mail host
 * configured, the {@code !prod} profile still active) the use cases inject this one and mail is
 * actually delivered. In {@code prod}/{@code production} the logging bean is absent by profile, so
 * an unset {@code spring.mail.host} leaves no {@link AccountEmailSender} at all and the context
 * fails to start rather than silently not sending — the ADR-0012 §6 guarantee, unchanged.
 *
 * <h2>This method never throws</h2>
 *
 * <p>The calling use cases have no failure branch by design: {@code RequestPasswordResetUseCase}
 * returns {@code 202} whether or not the account exists (no enumeration — OWASP), and the create
 * and reset flows have already committed the token or code by the time delivery is attempted. A
 * send failure here is logged and swallowed — exactly as the logging adapter cannot fail — and the
 * operator's recourse is "resend invitation" / "send reset code". A hung SMTP conversation is
 * bounded by the {@code spring.mail.properties.mail.smtp.*.timeout} values, not by this class.
 *
 * <h2>Platform-wide, for now</h2>
 *
 * <p>One {@code From} address and one SMTP account for the whole platform (ADR-0014). Per-tenant
 * sender identity, provider, and templates are ADR-0005's {@code EmailChannel}; when that lands
 * this adapter delegates to it rather than holding SMTP details itself.
 */
@Component
@Primary
@ConditionalOnProperty(prefix = "spring.mail", name = "host")
class SmtpAccountEmailSender implements AccountEmailSender {

  private static final Logger log = LoggerFactory.getLogger(SmtpAccountEmailSender.class);

  private final JavaMailSender mailSender;
  private final String from;
  private final String baseUrl;

  SmtpAccountEmailSender(
      JavaMailSender mailSender,
      @Value("${guardian.email.from:Guardian Platform <no-reply@localhost>}") String from,
      @Value("${guardian.admin.base-url:http://localhost:8081}") String baseUrl) {
    this.mailSender = mailSender;
    this.from = from;
    this.baseUrl = stripTrailingSlash(baseUrl);
  }

  @Override
  public void sendInvitation(String email, String firstName, String rawToken, Duration validFor) {
    String link = baseUrl + "/accept-invitation?token=" + rawToken;
    String body =
        greeting(firstName)
            + "An account has been created for you on the Guardian admin console.\n\n"
            + "Set your password and activate the account here:\n\n"
            + link
            + "\n\nThe link is valid for "
            + validFor.toHours()
            + " hours. If you were not expecting this, you can ignore this email.\n";
    send(email, "Activate your Guardian admin account", body);
  }

  @Override
  public void sendPasswordResetCode(
      String email, String firstName, String code, Duration validFor) {
    String body =
        greeting(firstName)
            + "Use this code to reset your Guardian admin console password:\n\n"
            + "    "
            + code
            + "\n\nThe code is valid for "
            + validFor.toMinutes()
            + " minutes and can be used once. If you did not request a reset, no action is "
            + "needed; your password has not changed.\n";
    send(email, "Your Guardian password reset code", body);
  }

  @Override
  public void sendPasswordChangedNotice(String email, String firstName) {
    String body =
        greeting(firstName)
            + "Your Guardian admin console password was just changed, and every signed-in "
            + "session was ended.\n\n"
            + "If this was not you, contact your administrator immediately.\n";
    send(email, "Your Guardian password was changed", body);
  }

  private void send(String to, String subject, String body) {
    SimpleMailMessage message = new SimpleMailMessage();
    message.setFrom(from);
    message.setTo(to);
    message.setSubject(subject);
    message.setText(body);
    try {
      mailSender.send(message);
    } catch (MailException e) {
      // Deliberately not rethrown — see the class comment. The token/code is already persisted;
      // the operator resends. The address is masked because a failed-delivery log line naming a
      // real recipient is the thing worth not writing.
      log.error("Account email '{}' to {} was not delivered", subject, maskEmail(to), e);
    }
  }

  private static String greeting(String firstName) {
    return (firstName == null || firstName.isBlank()
        ? "Hello,\n\n"
        : "Hello " + firstName + ",\n\n");
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
