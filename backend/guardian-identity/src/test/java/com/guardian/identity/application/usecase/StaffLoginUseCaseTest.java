package com.guardian.identity.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.AuthenticationFailedException;
import com.guardian.identity.application.command.StaffLoginCommand;
import com.guardian.identity.application.port.PasswordCredentialRepository;
import com.guardian.identity.application.port.PreAuthenticationDirectory;
import com.guardian.identity.application.port.PreAuthenticationDirectory.EmailMatch;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.application.result.IssuedSession;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.PasswordCredential;
import com.guardian.identity.domain.Session;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Unit tests for the use case. Ports are mocked; no Spring context, no database.
 *
 * <p>{@link TenantScopedTransaction} is mocked to run its supplier immediately rather than through
 * a real transaction — the boundary this use case actually owns is "resolve tenant, then verify",
 * not the transaction manager itself.
 */
@ExtendWith(MockitoExtension.class)
class StaffLoginUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final UserId USER = UserId.of(UUID.randomUUID());
  private static final String EMAIL = "anil@demo-trust.example";
  private static final String PASSWORD = "Guardian!Demo2026";
  private static final String HASH = "argon2-hash";

  @Mock private PreAuthenticationDirectory directory;
  @Mock private PasswordCredentialRepository passwordCredentials;
  @Mock private UserRepository users;
  @Mock private SecretHasher secretHasher;
  @Mock private SessionFactory sessionFactory;
  @Mock private AuditPort auditPort;
  @Mock private TenantScopedTransaction tenantScoped;

  private StaffLoginUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase =
        new StaffLoginUseCase(
            directory,
            passwordCredentials,
            users,
            secretHasher,
            sessionFactory,
            auditPort,
            tenantScoped);

    // Runs the supplier immediately, standing in for a real transaction boundary — see the
    // class documentation. `lenient()` because three tests below refuse before ever reaching
    // the transaction (an unknown email, an ambiguous match, an inactive account) and would
    // otherwise fail strict stubbing on an unused stub rather than on anything meaningful.
    lenient()
        .when(tenantScoped.execute(any(), any()))
        .thenAnswer(inv -> ((Supplier<?>) inv.getArgument(1)).get());
  }

  private static EmailMatch activeMatch() {
    return new EmailMatch(USER, TENANT, UserStatus.ACTIVE);
  }

  private static PasswordCredential credentialWith(int failedAttempts, Instant lockedUntil) {
    return PasswordCredential.rehydrate(
        UUID.randomUUID(), USER, HASH, failedAttempts, lockedUntil, 0);
  }

  private static User staffUser() {
    return User.rehydrate(USER, null, EMAIL, "Anil", "Kumar", "en", UserStatus.ACTIVE, null, 0);
  }

  private StaffLoginCommand command() {
    return new StaffLoginCommand(EMAIL, PASSWORD, "ADMIN_WEB", "203.0.113.5");
  }

  @Test
  @DisplayName("an unregistered email is refused with the same code as a wrong password")
  void unknownEmailIsRefusedUniformly() {
    when(directory.findByEmail(EMAIL)).thenReturn(List.of());

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(AuthenticationFailedException.class)
        .extracting(e -> ((AuthenticationFailedException) e).errorCode())
        .isEqualTo(ErrorCode.AUTH_CREDENTIALS_INVALID);

    verify(passwordCredentials, never()).save(any());
  }

  @Test
  @DisplayName("BR-IAM-003: more than one account across tenants is refused, never guessed")
  void ambiguousTenantMatchIsRefused() {
    EmailMatch otherTenant =
        new EmailMatch(
            UserId.of(UUID.randomUUID()), TenantId.of(UUID.randomUUID()), UserStatus.ACTIVE);
    when(directory.findByEmail(EMAIL)).thenReturn(List.of(activeMatch(), otherTenant));

    // Refused before a tenant is ever chosen — resolveSingleActiveUser throws ahead of the
    // tenantScoped.execute call, so there is no transaction, no lookup, and no lock write
    // charged against either account for a match that was never permitted to proceed.
    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(AuthenticationFailedException.class)
        .extracting(e -> ((AuthenticationFailedException) e).errorCode())
        .isEqualTo(ErrorCode.AUTH_CREDENTIALS_INVALID);

    verify(passwordCredentials, never()).findByUserId(any());
  }

  @Test
  @DisplayName("an inactive account is refused with the same code as an unknown one")
  void inactiveAccountIsRefusedUniformly() {
    when(directory.findByEmail(EMAIL))
        .thenReturn(List.of(new EmailMatch(USER, TENANT, UserStatus.INACTIVE)));

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(AuthenticationFailedException.class)
        .extracting(e -> ((AuthenticationFailedException) e).errorCode())
        .isEqualTo(ErrorCode.AUTH_CREDENTIALS_INVALID);
  }

  @Test
  @DisplayName("an account with no password ever set is refused, not distinguished")
  void noCredentialRowIsRefusedUniformly() {
    when(directory.findByEmail(EMAIL)).thenReturn(List.of(activeMatch()));
    when(passwordCredentials.findByUserId(USER)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(AuthenticationFailedException.class)
        .extracting(e -> ((AuthenticationFailedException) e).errorCode())
        .isEqualTo(ErrorCode.AUTH_CREDENTIALS_INVALID);
  }

  @Test
  @DisplayName("a locked credential is refused without ever comparing the password")
  void lockedCredentialIsRefused() {
    when(directory.findByEmail(EMAIL)).thenReturn(List.of(activeMatch()));
    when(passwordCredentials.findByUserId(USER))
        .thenReturn(Optional.of(credentialWith(5, Instant.now().plusSeconds(600))));

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(AuthenticationFailedException.class)
        .extracting(e -> ((AuthenticationFailedException) e).errorCode())
        .isEqualTo(ErrorCode.AUTH_ACCOUNT_LOCKED);

    verify(secretHasher, never()).matches(any(), any());
  }

  @Test
  @BusinessRule("BR-IAM-011")
  @DisplayName("a wrong password is recorded and refused, and locks the account at the threshold")
  void wrongPasswordLocksAtThreshold() {
    when(directory.findByEmail(EMAIL)).thenReturn(List.of(activeMatch()));
    when(passwordCredentials.findByUserId(USER))
        .thenReturn(Optional.of(credentialWith(PasswordCredential.MAX_ATTEMPTS - 1, null)));
    when(secretHasher.matches(eq(PASSWORD), eq(HASH))).thenReturn(false);
    when(passwordCredentials.save(any())).thenAnswer(inv -> inv.getArgument(0));

    assertThatThrownBy(() -> useCase.execute(command()))
        .isInstanceOf(AuthenticationFailedException.class)
        .extracting(e -> ((AuthenticationFailedException) e).errorCode())
        .isEqualTo(ErrorCode.AUTH_ACCOUNT_LOCKED);

    ArgumentCaptor<PasswordCredential> captor = ArgumentCaptor.forClass(PasswordCredential.class);
    verify(passwordCredentials).save(captor.capture());
    assertThat(captor.getValue().failedAttempts()).isEqualTo(PasswordCredential.MAX_ATTEMPTS);
    assertThat(captor.getValue().isLockedAt(Instant.now())).isTrue();

    verify(auditPort)
        .record(argThat((AuditRecord record) -> record.action().equals("AUTH_ACCOUNT_LOCKED")));
  }

  @Test
  @DisplayName("a correct password issues a session and resets the failure count")
  void correctPasswordSignsIn() {
    when(directory.findByEmail(EMAIL)).thenReturn(List.of(activeMatch()));
    when(passwordCredentials.findByUserId(USER)).thenReturn(Optional.of(credentialWith(2, null)));
    when(secretHasher.matches(eq(PASSWORD), eq(HASH))).thenReturn(true);
    when(passwordCredentials.save(any())).thenAnswer(inv -> inv.getArgument(0));
    when(users.findById(USER)).thenReturn(Optional.of(staffUser()));
    when(users.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Session session =
        Session.start(USER, ClientType.ADMIN_WEB, "refresh-hash", null, Instant.now());
    IssuedSession response =
        new IssuedSession(
            "access-token",
            "refresh-token",
            900,
            new IssuedSession.AuthenticatedUserView(
                USER.value().toString(), "Anil", "Kumar", "en", List.of("TRANSPORT_MANAGER")));
    when(sessionFactory.startSession(any(), eq(TENANT), eq(ClientType.ADMIN_WEB), any(), any()))
        .thenReturn(new SessionFactory.Issued(session, response));

    IssuedSession result = useCase.execute(command());

    assertThat(result.accessToken()).isEqualTo("access-token");
    assertThat(result.user().roles()).containsExactly("TRANSPORT_MANAGER");

    ArgumentCaptor<PasswordCredential> captor = ArgumentCaptor.forClass(PasswordCredential.class);
    verify(passwordCredentials).save(captor.capture());
    assertThat(captor.getValue().failedAttempts()).isZero();

    verify(auditPort)
        .record(argThat((AuditRecord record) -> record.action().equals("AUTH_SIGNED_IN")));
  }
}
