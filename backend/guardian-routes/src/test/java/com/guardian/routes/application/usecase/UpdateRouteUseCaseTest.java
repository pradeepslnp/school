package com.guardian.routes.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.routes.application.command.UpdateRouteCommand;
import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.domain.OperatingDays;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.SchoolId;
import java.time.DayOfWeek;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Unit tests for editing a route (RTE-001).
 *
 * <p>Operating days get the most attention here because that field decides whether MOD-08 generates
 * a trip at all: getting it wrong does not produce a visibly broken screen, it produces a bus that
 * quietly does not run.
 */
@ExtendWith(MockitoExtension.class)
class UpdateRouteUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final RouteId ROUTE = RouteId.generate();
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private RouteRepository routeRepository;
  @Mock private AuditPort auditPort;

  private UpdateRouteUseCase useCase;

  @BeforeEach
  void setUp() {
    TenantContext.set(TENANT);
    useCase = new UpdateRouteUseCase(routeRepository, auditPort);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private static Route existingRoute() {
    return new Route(
        ROUTE,
        TENANT,
        SchoolId.of(UUID.randomUUID()),
        "R3",
        "Green Park",
        null,
        OperatingDays.schoolWeek(),
        true,
        3L);
  }

  @Test
  @DisplayName("adding Saturday changes only the operating days")
  void updatesOperatingDays() {
    when(routeRepository.findById(ROUTE)).thenReturn(Optional.of(existingRoute()));
    when(routeRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Route saved =
        useCase.execute(
            new UpdateRouteCommand(
                ROUTE,
                null,
                null,
                OperatingDays.parse("MON,TUE,WED,THU,FRI,SAT"),
                ACTOR,
                "TRANSPORT_MANAGER"));

    assertThat(saved.operatingDays().includes(DayOfWeek.SATURDAY)).isTrue();
    assertThat(saved.name()).isEqualTo("Green Park");
    assertThat(saved.active()).isTrue();
  }

  @Test
  @DisplayName("null means leave unchanged, so a name-only edit keeps the operating days")
  void leavesOmittedFieldsAlone() {
    when(routeRepository.findById(ROUTE)).thenReturn(Optional.of(existingRoute()));
    when(routeRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Route saved =
        useCase.execute(
            new UpdateRouteCommand(
                ROUTE, "Green Park North", null, null, ACTOR, "TRANSPORT_MANAGER"));

    assertThat(saved.name()).isEqualTo("Green Park North");
    assertThat(saved.operatingDays().toStoredValue()).isEqualTo("MON,TUE,WED,THU,FRI");
  }

  @Test
  @DisplayName("the code is never editable — it labels trips and printed lists already in use")
  void codeIsNotEditable() {
    when(routeRepository.findById(ROUTE)).thenReturn(Optional.of(existingRoute()));
    when(routeRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Route saved =
        useCase.execute(
            new UpdateRouteCommand(
                ROUTE, "Renamed", null, null, ACTOR, "TRANSPORT_MANAGER"));

    assertThat(saved.code()).isEqualTo("R3");
  }

  @Test
  @DisplayName("the audit record carries the old days as well as the new ones")
  void auditsBeforeAndAfter() {
    when(routeRepository.findById(ROUTE)).thenReturn(Optional.of(existingRoute()));
    when(routeRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(
        new UpdateRouteCommand(
            ROUTE, null, null, OperatingDays.parse("MON,WED,FRI"), ACTOR, "SCHOOL_ADMIN"));

    ArgumentCaptor<AuditRecord> record = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(record.capture());

    assertThat(record.getValue().action()).isEqualTo("ROUTE_UPDATED");
    // "Who stopped the Tuesday service?" is answerable only if the old value was kept.
    assertThat(record.getValue().beforeValues())
        .containsEntry("operatingDays", "MON,TUE,WED,THU,FRI");
    assertThat(record.getValue().afterValues()).containsEntry("operatingDays", "MON,WED,FRI");
  }

  @Test
  @DisplayName("an unknown route is refused before anything is written")
  void refusesUnknownRoute() {
    when(routeRepository.findById(ROUTE)).thenReturn(Optional.empty());

    assertThatThrownBy(
            () ->
                useCase.execute(
                    new UpdateRouteCommand(
                        ROUTE, "X", null, null, ACTOR, "TRANSPORT_MANAGER")))
        .isInstanceOf(ResourceNotFoundException.class)
        .extracting(e -> ((ResourceNotFoundException) e).errorCode())
        .isEqualTo(ErrorCode.ROUTE_NOT_FOUND);

    verify(routeRepository, never()).save(any());
    verify(auditPort, never()).record(any());
  }
}
