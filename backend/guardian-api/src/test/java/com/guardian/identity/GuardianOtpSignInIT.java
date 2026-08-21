package com.guardian.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.AbstractIntegrationTest;
import com.guardian.common.BusinessRule;
import com.guardian.common.error.DomainException;
import com.guardian.common.error.ErrorCode;
import com.guardian.identity.application.command.RequestOtpCommand;
import com.guardian.identity.application.command.VerifyOtpCommand;
import com.guardian.identity.application.port.AccessTokenVerifier;
import com.guardian.identity.application.port.OtpSender;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.application.usecase.RefreshSessionUseCase;
import com.guardian.identity.application.usecase.RequestOtpUseCase;
import com.guardian.identity.application.usecase.VerifyOtpUseCase;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.PhoneNumber;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ContextConfiguration;

/**
 * The guardian sign-in flow, end to end against real PostgreSQL with row-level security in force.
 *
 * <p>These assertions are integration-level rather than unit-level on purpose. The parts most
 * likely to be wrong here are not the rules — those have unit tests — but the plumbing around them:
 * whether the pre-authentication lookup can see across tenants, whether the writes that follow it
 * land under the right tenant, and whether a failed attempt survives the exception that reports it.
 * None of that is observable without a database.
 */
@ContextConfiguration(classes = GuardianOtpSignInIT.RecordingOtpSenderConfiguration.class)
class GuardianOtpSignInIT extends AbstractIntegrationTest {

  /** The number a guardian types. Stored normalised; entered here as a human would enter it. */
  private static final String TYPED_PHONE = "+91 80506 02046";

  private static final UUID GUARDIAN_ID = UUID.randomUUID();
  private static final UUID GUARDIAN_ROLE_ID = UUID.randomUUID();

  @Autowired private RequestOtpUseCase requestOtp;
  @Autowired private VerifyOtpUseCase verifyOtp;
  @Autowired private RefreshSessionUseCase refreshSession;
  @Autowired private AccessTokenVerifier accessTokenVerifier;
  @Autowired private RecordingOtpSender otpSender;

  /**
   * Captures the code instead of sending it.
   *
   * <p>{@code @Primary} over the development logging sender. Reading the code out of a log would
   * make the test depend on a log format, which is not a contract.
   *
   * <p>Registered through {@code @ContextConfiguration} on the class rather than left as a bare
   * nested {@code @TestConfiguration}. Nested test configuration is only auto-detected on the class
   * that carries {@code @SpringBootTest}, and here that annotation lives on {@link
   * AbstractIntegrationTest} — so the nested form is silently ignored and every test in this file
   * fails to autowire.
   */
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

    void forget() {
      this.lastCode = null;
    }
  }

  @BeforeEach
  void seedGuardian() {
    otpSender.forget();

    // Seeded as owner, which is a superuser in the test container and so bypasses RLS. This is
    // the school registering a guardian; the sign-in flow never creates a user.
    JdbcTemplate owner = ownerJdbcTemplate();

    // audit_records deliberately has no foreign key to organizations, so the base class's
    // TRUNCATE ... CASCADE does not reach it and rows outlive the test that wrote them.
    // TRUNCATE rather than DELETE: the table is append-only, enforced by a BEFORE DELETE
    // trigger that fires for the superuser too.
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
  @DisplayName(
      "verifying a code records the sign-in against the guardian's number and opens a session")
  void signInPersistsAgainstTheGuardiansRow() {
    IssuedSession session = signIn();

    assertThat(session.accessToken()).isNotBlank();
    assertThat(session.refreshToken()).isNotBlank();
    assertThat(session.user().id()).isEqualTo(GUARDIAN_ID.toString());
    assertThat(session.user().firstName()).isEqualTo("Asha");
    assertThat(session.user().roles()).containsExactly("GUARDIAN");

    JdbcTemplate owner = ownerJdbcTemplate();

    // The row keyed by the mobile number now carries the sign-in. This is the durable effect
    // of typing a number and a code.
    Boolean recorded =
        owner.queryForObject(
            "SELECT last_login_at IS NOT NULL FROM users WHERE id = ?", Boolean.class, GUARDIAN_ID);
    assertThat(recorded).isTrue();

    Map<String, Object> stored =
        owner.queryForMap(
            "SELECT tenant_id, user_id, client_type, refresh_token_hash FROM sessions");

    assertThat(stored.get("tenant_id")).isEqualTo(ORGANIZATION_A);
    assertThat(stored.get("user_id")).isEqualTo(GUARDIAN_ID);
    assertThat(stored.get("client_type")).isEqualTo("PARENT_APP");
    // Only ever a hash. A database copy must not yield usable sessions.
    assertThat(stored.get("refresh_token_hash")).isNotEqualTo(session.refreshToken());
  }

  @Test
  @BusinessRule("BR-TEN-004")
  @DisplayName("the access token binds the tenant the number belongs to")
  void accessTokenCarriesTheResolvedTenant() {
    IssuedSession session = signIn();

    var verified = accessTokenVerifier.verify(session.accessToken());

    assertThat(verified).isPresent();
    // The tenant came from the server-side phone lookup, not from anything the client sent.
    // This claim seeds row-level security on every later request, so a token cannot address
    // another organization's children.
    assertThat(verified.get().tenantId()).isEqualTo(TENANT_A);
    assertThat(verified.get().userId().value()).isEqualTo(GUARDIAN_ID);
  }

  @Test
  @DisplayName("a code works once")
  void otpIsSingleUse() {
    requestOtp.execute(new RequestOtpCommand(TYPED_PHONE, "203.0.113.4"));
    String code = otpSender.lastCode();

    verifyOtp.execute(verify(code));

    assertThatThrownBy(() -> verifyOtp.execute(verify(code)))
        .isInstanceOfSatisfying(
            DomainException.class,
            e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.AUTH_OTP_ALREADY_USED));
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("wrong codes accumulate across requests and lock the account")
  void failedAttemptsSurviveTheirOwnRejection() {
    requestOtp.execute(new RequestOtpCommand(TYPED_PHONE, "203.0.113.4"));
    String realCode = otpSender.lastCode();
    String wrongCode = wrongCodeOtherThan(realCode);

    for (int attempt = 1; attempt < OtpCredential.MAX_ATTEMPTS; attempt++) {
      assertThatThrownBy(() -> verifyOtp.execute(verify(wrongCode)))
          .isInstanceOfSatisfying(
              DomainException.class,
              e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.AUTH_CREDENTIALS_INVALID));
    }

    // The counter only reaches five if each rejection committed. Were the failure thrown from
    // inside the transaction, every increment would roll back with it, the lock would never
    // engage, and the endpoint would still answer "invalid" — a limit that exists only on paper.
    Integer attempts =
        ownerJdbcTemplate()
            .queryForObject(
                "SELECT failed_attempts FROM user_credentials WHERE user_id = ?",
                Integer.class,
                GUARDIAN_ID);
    assertThat(attempts).isEqualTo(OtpCredential.MAX_ATTEMPTS - 1);

    assertThatThrownBy(() -> verifyOtp.execute(verify(wrongCode)))
        .isInstanceOfSatisfying(
            DomainException.class,
            e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.AUTH_ACCOUNT_LOCKED));

    // And the correct code no longer helps: a lock that a valid code walks through protects
    // nothing, because the attacker's next guess is the one that succeeds.
    assertThatThrownBy(() -> verifyOtp.execute(verify(realCode)))
        .isInstanceOfSatisfying(
            DomainException.class,
            e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.AUTH_ACCOUNT_LOCKED));
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("asking for a new code does not clear an existing lock")
  void lockSurvivesAFreshRequest() {
    requestOtp.execute(new RequestOtpCommand(TYPED_PHONE, "203.0.113.4"));
    String wrongCode = wrongCodeOtherThan(otpSender.lastCode());

    for (int attempt = 0; attempt < OtpCredential.MAX_ATTEMPTS; attempt++) {
      assertThatThrownBy(() -> verifyOtp.execute(verify(wrongCode))).isNotNull();
    }

    otpSender.forget();
    requestOtp.execute(new RequestOtpCommand(TYPED_PHONE, "203.0.113.4"));

    // No new code is issued at all. Otherwise the attempt limit is decorative: five guesses,
    // request a fresh code, five more, indefinitely.
    assertThat(otpSender.lastCode()).isNull();
  }

  @Test
  @BusinessRule("BR-IAM-009")
  @DisplayName("reusing a rotated refresh token revokes the whole family")
  void refreshReuseRevokesTheFamily() {
    IssuedSession first = signIn();

    IssuedSession second = refreshSession.execute(first.refreshToken());
    assertThat(second.refreshToken()).isNotEqualTo(first.refreshToken());

    // The first token was consumed by that rotation. Presenting it again means two parties
    // hold it, and which one is asking cannot be determined.
    assertThatThrownBy(() -> refreshSession.execute(first.refreshToken()))
        .isInstanceOfSatisfying(
            DomainException.class,
            e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.AUTH_REFRESH_REUSE_DETECTED));

    Integer live =
        ownerJdbcTemplate()
            .queryForObject("SELECT COUNT(*) FROM sessions WHERE NOT is_revoked", Integer.class);
    assertThat(live).isZero();
  }

  @Test
  @BusinessRule("BR-IAM-007")
  @DisplayName("a revoked session's refresh token stops working immediately")
  void revokedSessionCannotRefresh() {
    IssuedSession first = signIn();
    IssuedSession second = refreshSession.execute(first.refreshToken());

    // Reuse of the old token revokes the family, which includes the token the legitimate
    // client is holding. Signing that client out too is the intended cost.
    assertThatThrownBy(() -> refreshSession.execute(first.refreshToken())).isNotNull();

    assertThatThrownBy(() -> refreshSession.execute(second.refreshToken()))
        .isInstanceOfSatisfying(
            DomainException.class,
            e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.AUTH_SESSION_REVOKED));
  }

  @Test
  @DisplayName("an unregistered number is answered in silence, and cannot sign in")
  void unregisteredNumberRevealsNothing() {
    requestOtp.execute(new RequestOtpCommand("+91 99999 00000", "203.0.113.4"));

    // No code sent, no credential row, no exception — the caller cannot distinguish this from
    // a registered number.
    assertThat(otpSender.lastCode()).isNull();

    Integer credentials =
        ownerJdbcTemplate().queryForObject("SELECT COUNT(*) FROM user_credentials", Integer.class);
    assertThat(credentials).isZero();

    assertThatThrownBy(
            () ->
                verifyOtp.execute(
                    new VerifyOtpCommand(
                        "+91 99999 00000", "123456", "PARENT_APP", "Pixel 8", "203.0.113.4")))
        .isInstanceOfSatisfying(
            DomainException.class,
            e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.AUTH_CREDENTIALS_INVALID));
  }

  @Test
  @DisplayName("an inactive guardian is refused, indistinguishably from an unknown number")
  void inactiveGuardianIsRefused() {
    ownerJdbcTemplate().update("UPDATE users SET status = 'INACTIVE' WHERE id = ?", GUARDIAN_ID);

    requestOtp.execute(new RequestOtpCommand(TYPED_PHONE, "203.0.113.4"));
    assertThat(otpSender.lastCode()).isNull();

    assertThatThrownBy(() -> verifyOtp.execute(verify("123456")))
        .isInstanceOfSatisfying(
            DomainException.class,
            e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.AUTH_CREDENTIALS_INVALID));
  }

  @Test
  @DisplayName("the audit trail records the sign-in without the number or the code")
  void signInIsAuditedWithoutCredentials() {
    signIn();

    List<Map<String, Object>> records =
        ownerJdbcTemplate()
            .queryForList(
                """
                SELECT action, after_values::text AS after_values
                FROM audit_records
                WHERE tenant_id = ? AND action IN ('AUTH_OTP_REQUESTED', 'AUTH_SIGNED_IN')
                """,
                ORGANIZATION_A);

    assertThat(records).hasSize(2);

    String allValues =
        records.stream()
            .map(row -> String.valueOf(row.get("after_values")))
            .reduce("", String::concat);

    // The full number and the code are both credentials in a table more people can read than
    // the users table. The masked tail is enough for support to confirm who they are looking at.
    assertThat(allValues).doesNotContain(PhoneNumber.of(TYPED_PHONE).value());
    assertThat(allValues).contains("2046");
  }

  // --- helpers ------------------------------------------------------------------------

  private IssuedSession signIn() {
    requestOtp.execute(new RequestOtpCommand(TYPED_PHONE, "203.0.113.4"));
    return verifyOtp.execute(verify(otpSender.lastCode()));
  }

  private static VerifyOtpCommand verify(String code) {
    return new VerifyOtpCommand(TYPED_PHONE, code, "PARENT_APP", "Pixel 8", "203.0.113.4");
  }

  /** A well-formed code that is definitely not the issued one. */
  private static String wrongCodeOtherThan(String realCode) {
    return "000000".equals(realCode) ? "111111" : "000000";
  }
}
