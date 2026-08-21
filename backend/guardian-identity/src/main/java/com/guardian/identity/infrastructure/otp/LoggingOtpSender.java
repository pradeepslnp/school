package com.guardian.identity.infrastructure.otp;

import com.guardian.identity.application.port.OtpSender;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.PhoneNumber;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Writes the code to the application log instead of sending an SMS.
 *
 * <p>Exists so the sign-in flow can be exercised end to end with no SMS provider, no credentials,
 * and no per-message cost during development.
 *
 * <p><strong>This deliberately violates a platform invariant, and the violation is contained by
 * construction.</strong> SECURITY_ARCHITECTURE.md §"Never logged" lists OTPs alongside passwords
 * and tokens, and it is right to: a code in a log is a credential in whatever aggregator, terminal
 * scrollback, or support ticket that log reaches.
 *
 * <p>So this bean is gated by {@code @Profile("!prod & !production")} rather than by an {@code if}.
 * The distinction matters — a conditional inside the method would still be a code path that exists
 * in a production binary and could be reached by a misread flag. A profile-gated bean is simply not
 * registered, and a production deployment with no other {@link OtpSender} on the classpath fails to
 * start rather than quietly logging guardians' codes.
 *
 * <p>Replacing this is what makes the flow real: an SMS adapter implements the same port and this
 * class is not touched.
 */
@Component
@Profile("!prod & !production")
class LoggingOtpSender implements OtpSender {

  private static final Logger log = LoggerFactory.getLogger(LoggingOtpSender.class);

  @Override
  public void send(PhoneNumber phone, OtpCode code, Duration validFor) {
    // The number is masked even here. The code is not — reading it is the entire purpose —
    // but the pair of them together is what would identify a family, so they are never both
    // in full.
    log.warn(
        "DEVELOPMENT OTP for {} is {} (valid {}s). No SMS was sent.",
        phone.masked(),
        code.value(),
        validFor.toSeconds());
  }
}
