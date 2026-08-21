package com.guardian.identity;

import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.AbstractIntegrationTest;
import com.guardian.identity.application.command.RequestOtpCommand;
import com.guardian.identity.application.port.OtpSender;
import com.guardian.identity.application.usecase.RequestOtpUseCase;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.PhoneNumber;
import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;

@TestPropertySource(properties = "guardian.auth.magic-otp=123456")
@ContextConfiguration(classes = GuardianMagicOtpIT.RecordingOtpSenderConfiguration.class)
class GuardianMagicOtpIT extends AbstractIntegrationTest {

  private static final String TYPED_PHONE = "+91 80506 02046";
  private static final UUID GUARDIAN_ID = UUID.randomUUID();
  private static final UUID GUARDIAN_ROLE_ID = UUID.randomUUID();

  @Autowired private RequestOtpUseCase requestOtp;
  @Autowired private RecordingOtpSender otpSender;

  @TestConfiguration
  static class RecordingOtpSenderConfiguration {

    @Bean
    @Primary
    RecordingOtpSender recordingOtpSender() {
      return new RecordingOtpSender();
    }
  }

  static class RecordingOtpSender implements OtpSender {
    private volatile String lastCode;

    @Override
    public void send(PhoneNumber phone, OtpCode code, Duration validFor) {
      this.lastCode = code.value();
    }

    String lastCode() {
      return lastCode;
    }
  }

  @BeforeEach
  void seedGuardian() {
    JdbcTemplate owner = ownerJdbcTemplate();
    owner.execute("TRUNCATE TABLE audit_records");

    owner.update(
        """
        INSERT INTO roles (id, tenant_id, code, name, is_system_role)
        VALUES (?, ?, 'GUARDIAN', 'Guardian', true)
        """,
        GUARDIAN_ROLE_ID,
        ORGANIZATION_A);

    owner.update(
        """
        INSERT INTO users (id, tenant_id, phone, first_name, last_name, preferred_locale, status)
        VALUES (?, ?, ?, 'Asha', 'Rao', 'en', 'ACTIVE')
        """,
        GUARDIAN_ID,
        ORGANIZATION_A,
        PhoneNumber.of(TYPED_PHONE).value());

    owner.update(
        "INSERT INTO user_roles (id, tenant_id, user_id, role_id) VALUES (?, ?, ?, ?)",
        UUID.randomUUID(),
        ORGANIZATION_A,
        GUARDIAN_ID,
        GUARDIAN_ROLE_ID);
  }

  @Test
  void configuredMagicOtpIsUsedForOtpRequests() {
    requestOtp.execute(new RequestOtpCommand(TYPED_PHONE, "203.0.113.4"));

    assertThat(otpSender.lastCode()).isEqualTo("123456");
  }
}
