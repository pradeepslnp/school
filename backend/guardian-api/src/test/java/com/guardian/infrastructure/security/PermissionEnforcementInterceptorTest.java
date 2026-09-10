package com.guardian.infrastructure.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.guardian.common.error.OrganizationSuspendedException;
import com.guardian.common.error.PermissionDeniedException;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.identity.application.port.PermissionResolver;
import com.guardian.identity.domain.UserId;
import com.guardian.infrastructure.tenant.GuardianPrincipal;
import com.guardian.tenancy.application.port.OrganizationRepository;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationCode;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.OrganizationStatus;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.method.HandlerMethod;

/**
 * Unit tests for {@link PermissionEnforcementInterceptor}, focused on the organization-suspension
 * check (BR-TEN-006) added alongside TEN-004. {@code PermissionResolver} and {@code
 * OrganizationRepository} are mocked; {@link SecurityContextHolder} and {@link TenantContext} are
 * set to real values rather than mocked, matching how {@code AbstractIntegrationTest} manages them
 * — both are plain static holders, not collaborators worth mocking.
 */
@ExtendWith(MockitoExtension.class)
class PermissionEnforcementInterceptorTest {

  private static final UUID ORG_UUID = UUID.randomUUID();
  private static final UUID ACTOR_ID = UUID.randomUUID();
  private static final OrganizationId ORG_ID = OrganizationId.of(ORG_UUID);
  private static final TenantId TENANT_ID = TenantId.of(ORG_UUID);

  @Mock private PermissionResolver permissionResolver;
  @Mock private OrganizationRepository organizationRepository;

  private PermissionEnforcementInterceptor interceptor;
  private final MockHttpServletRequest request = new MockHttpServletRequest();
  private final MockHttpServletResponse response = new MockHttpServletResponse();

  @BeforeEach
  void setUp() {
    interceptor = new PermissionEnforcementInterceptor(permissionResolver, organizationRepository);

    GuardianPrincipal principal =
        new GuardianPrincipal(CurrentActor.of(ACTOR_ID, "SCHOOL_ADMIN"), TENANT_ID);
    SecurityContextHolder.getContext()
        .setAuthentication(new TestingAuthenticationToken(principal, null));
    TenantContext.set(TENANT_ID);
  }

  @AfterEach
  void tearDown() {
    SecurityContextHolder.clearContext();
    TenantContext.clear();
  }

  private static Organization organizationWithStatus(OrganizationStatus status) {
    return new Organization(
        ORG_ID, OrganizationCode.of("GREENWOOD"), "Greenwood", "IN", status, null, null, 0L);
  }

  private HandlerMethod handlerFor(String methodName) throws NoSuchMethodException {
    return new HandlerMethod(new TestController(), TestController.class.getMethod(methodName));
  }

  @Test
  @DisplayName("an active organization's caller passes through")
  void activeOrganizationPasses() throws NoSuchMethodException {
    when(permissionResolver.resolve(UserId.of(ACTOR_ID))).thenReturn(Set.of("PERM-STUDENT-VIEW"));
    when(organizationRepository.findById(ORG_ID))
        .thenReturn(Optional.of(organizationWithStatus(OrganizationStatus.ACTIVE)));

    boolean result = interceptor.preHandle(request, response, handlerFor("nonSafetyAction"));

    assertThat(result).isTrue();
  }

  @Test
  @DisplayName("a suspended organization's caller is refused a non-safety permission")
  void suspendedOrganizationRefusesOrdinaryPermission() throws NoSuchMethodException {
    when(permissionResolver.resolve(UserId.of(ACTOR_ID))).thenReturn(Set.of("PERM-STUDENT-VIEW"));
    when(organizationRepository.findById(ORG_ID))
        .thenReturn(Optional.of(organizationWithStatus(OrganizationStatus.SUSPENDED)));

    assertThatThrownBy(
            () -> interceptor.preHandle(request, response, handlerFor("nonSafetyAction")))
        .isInstanceOf(OrganizationSuspendedException.class);
  }

  @Test
  @DisplayName("a suspended organization's caller still reaches a safety-critical permission")
  void suspendedOrganizationAllowsSafetyPermission() throws NoSuchMethodException {
    when(permissionResolver.resolve(UserId.of(ACTOR_ID))).thenReturn(Set.of("PERM-TRIP-START"));
    when(organizationRepository.findById(ORG_ID))
        .thenReturn(Optional.of(organizationWithStatus(OrganizationStatus.SUSPENDED)));

    boolean result = interceptor.preHandle(request, response, handlerFor("safetyAction"));

    assertThat(result).isTrue();
  }

  @Test
  @DisplayName(
      "the permission check still runs first: an unheld permission is refused before the suspension check")
  void permissionDeniedTakesPriorityOverSuspension() throws NoSuchMethodException {
    when(permissionResolver.resolve(UserId.of(ACTOR_ID))).thenReturn(Set.of());

    assertThatThrownBy(
            () -> interceptor.preHandle(request, response, handlerFor("nonSafetyAction")))
        .isInstanceOf(PermissionDeniedException.class);
  }

  /** Fixture controller supplying real, annotated methods for {@link HandlerMethod}. */
  static class TestController {

    @RequiresPermission("PERM-STUDENT-VIEW")
    public void nonSafetyAction() {}

    @RequiresPermission("PERM-TRIP-START")
    public void safetyAction() {}
  }
}
