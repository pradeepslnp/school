package com.guardian.identity.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.command.ProvisionStaffAccountCommand;
import com.guardian.identity.application.port.RoleProvisioningPort;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.RoleId;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/** Unit tests for the use case. Ports are mocked; no Spring context, no database. */
@ExtendWith(MockitoExtension.class)
class ProvisionStaffAccountUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private UserRepository users;
  @Mock private RoleProvisioningPort roleProvisioning;
  @Mock private AuditPort auditPort;

  private ProvisionStaffAccountUseCase useCase;

  @BeforeEach
  void setUp() {
    TenantContext.set(TENANT);
    useCase = new ProvisionStaffAccountUseCase(users, roleProvisioning, auditPort);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static ProvisionStaffAccountCommand command() {
    return new ProvisionStaffAccountCommand(
        "9876500001", "Ravi", "Kumar", "DRIVER", "Driver", ACTOR, "TRANSPORT_MANAGER");
  }

  @Test
  @DisplayName("creates a new user when the phone has no account in this tenant")
  void createsANewUserWhenNoneExists() {
    UUID roleId = UUID.randomUUID();
    when(users.findByPhone(any())).thenReturn(Optional.empty());
    when(users.create(any())).thenAnswer(inv -> inv.getArgument(0));
    when(roleProvisioning.findOrCreateSystemRole(eq(TENANT), eq("DRIVER"), eq("Driver")))
        .thenReturn(RoleId.of(roleId));

    UserId result = useCase.execute(command());

    assertThat(result).isNotNull();
    verify(users).create(any());
    verify(roleProvisioning).grantIfMissing(TENANT, result, RoleId.of(roleId));
  }

  @Test
  @DisplayName("reuses an existing user for the same phone rather than minting a second account")
  void reusesAnExistingUser() {
    User existing =
        User.rehydrate(
            UserId.of(UUID.randomUUID()),
            PhoneNumber.of("9876500001"),
            null,
            "Ravi",
            "Kumar",
            "en",
            com.guardian.identity.domain.UserStatus.ACTIVE,
            null,
            0L);
    when(users.findByPhone(any())).thenReturn(Optional.of(existing));
    when(roleProvisioning.findOrCreateSystemRole(any(), any(), any()))
        .thenReturn(RoleId.of(UUID.randomUUID()));

    UserId result = useCase.execute(command());

    assertThat(result).isEqualTo(existing.id());
    verify(users, never()).create(any());
  }

  @Test
  @DisplayName("a malformed phone is refused as a validation failure, not an internal error")
  void malformedPhoneIsRefused() {
    ProvisionStaffAccountCommand command =
        new ProvisionStaffAccountCommand(
            "abc", "Ravi", "Kumar", "DRIVER", "Driver", ACTOR, "TRANSPORT_MANAGER");

    assertThatThrownBy(() -> useCase.execute(command))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.VALIDATION_INVALID_FORMAT);
  }
}
