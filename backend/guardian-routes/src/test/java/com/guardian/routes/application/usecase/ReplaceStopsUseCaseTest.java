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
import com.guardian.routes.application.command.ReplaceStopsCommand;
import com.guardian.routes.application.command.StopInput;
import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.application.port.StopRepository;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.SchoolId;
import com.guardian.routes.domain.Stop;
import java.time.LocalTime;
import java.util.List;
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
class ReplaceStopsUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final RouteId ROUTE = RouteId.generate();
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private RouteRepository routeRepository;
  @Mock private StopRepository stopRepository;
  @Mock private AuditPort auditPort;

  private ReplaceStopsUseCase useCase;

  @BeforeEach
  void setUp() {
    useCase = new ReplaceStopsUseCase(routeRepository, stopRepository, auditPort);
    TenantContext.set(TENANT);
    when(routeRepository.findById(ROUTE))
        .thenReturn(
            Optional.of(
                Route.create(TENANT, SchoolId.of(UUID.randomUUID()), "R3", "Green Park", null)));
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static StopInput aStop(int sequenceNo, LocalTime pickup) {
    return new StopInput(sequenceNo, "Stop " + sequenceNo, 28.5, 77.2, 100, pickup, null, null);
  }

  @Test
  @DisplayName("replaces the stop list when there are at least two stops with increasing times")
  void replacesStops() {
    ReplaceStopsCommand command =
        new ReplaceStopsCommand(
            ROUTE,
            List.of(aStop(1, LocalTime.of(7, 30)), aStop(2, LocalTime.of(7, 40))),
            ACTOR,
            "TRANSPORT_MANAGER");

    List<Stop> result = useCase.execute(command);

    assertThat(result).hasSize(2);
    verify(stopRepository).replaceAll(any(), any());
  }

  @Test
  @com.guardian.common.BusinessRule("BR-ROUTE-001")
  @DisplayName("refuses fewer than two stops")
  void refusesTooFewStops() {
    ReplaceStopsCommand command =
        new ReplaceStopsCommand(ROUTE, List.of(aStop(1, null)), ACTOR, "TRANSPORT_MANAGER");

    assertThatThrownBy(() -> useCase.execute(command))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.ROUTE_MINIMUM_STOPS_REQUIRED);

    verify(stopRepository, never()).replaceAll(any(), any());
  }

  @Test
  @com.guardian.common.BusinessRule("BR-ROUTE-008")
  @DisplayName("refuses times that do not strictly increase along the sequence")
  void refusesNonIncreasingTimes() {
    ReplaceStopsCommand command =
        new ReplaceStopsCommand(
            ROUTE,
            List.of(aStop(1, LocalTime.of(7, 40)), aStop(2, LocalTime.of(7, 30))),
            ACTOR,
            "TRANSPORT_MANAGER");

    assertThatThrownBy(() -> useCase.execute(command))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.ROUTE_STOP_TIMES_NOT_INCREASING);

    verify(stopRepository, never()).replaceAll(any(), any());
  }
}
