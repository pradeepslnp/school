package com.guardian.identity.application.port;

import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.PhoneNumber;
import java.time.Duration;

/**
 * Delivers a one-time code to a guardian.
 *
 * <p>Behind a port so a new SMS vendor is additive and never reaches a use case (ADR-0004,
 * ADR-0005). The use case must not know whether delivery happened over SMS, WhatsApp, or a log
 * line.
 *
 * <p><strong>Delivery failure is not the caller's problem.</strong> Implementations swallow
 * transport faults and log them: {@code POST /auth/otp/request} answers {@code 202} whether or not
 * the number is registered, so it cannot start reporting provider errors without also revealing
 * which numbers exist.
 */
public interface OtpSender {

  /**
   * @param validFor how long the code remains usable, so the message can say so
   */
  void send(PhoneNumber phone, OtpCode code, Duration validFor);
}
