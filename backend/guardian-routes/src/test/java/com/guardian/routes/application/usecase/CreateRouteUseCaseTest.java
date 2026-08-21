package com.guardian.routes.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.routes.application.command.CreateRouteCommand;
import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.SchoolId;
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
class CreateRouteUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final SchoolId SCHOOL = SchoolId.of(UUID.randomUUID());
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private RouteRepository routeRepository;
  @Mock private AuditPort auditPort;

  private CreateRouteUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new CreateRouteUseCase(routeRepository, auditPort);
    TenantContext.set(TENANT);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static CreateRouteCommand aCommand() {
    return new CreateRouteCommand(SCHOOL, "R3", "Green Park", null, ACTOR, "TRANSPORT_MANAGER");
  }

  @Test
  @DisplayName("creates a route with a unique code")
  void createsRoute() {
    when(routeRepository.existsByCode(any(), any())).thenReturn(false);
    when(routeRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Route created = useCase.execute(aCommand());

    assertThat(created.code()).isEqualTo("R3");
    assertThat(created.active()).isTrue();
  }

  @Test
  @com.guardian.common.BusinessRule("BR-ROUTE-001")
  @DisplayName("refuses a code already used within the school")
  void refusesDuplicateCode() {
    when(routeRepository.existsByCode(any(), any())).thenReturn(true);

    assertThatThrownBy(() -> useCase.execute(aCommand()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.ROUTE_CODE_ALREADY_EXISTS);

    verify(routeRepository, never()).save(any());
    verify(auditPort, never()).record(any());
  }
}
