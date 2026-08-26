package com.guardian.tenancy.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.tenancy.application.port.PlatformOrganizationDirectory;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationCode;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.OrganizationStatus;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/** Unit tests for the use case (A-62). The directory port is mocked; no Spring context. */
@ExtendWith(MockitoExtension.class)
class GetPlatformHealthUseCaseTest {

  @Mock private PlatformOrganizationDirectory directory;

  private GetPlatformHealthUseCase useCase;

  private static Organization organizationWithStatus(OrganizationStatus status) {
    return new Organization(
        OrganizationId.generate(),
        OrganizationCode.of("ORG" + status.ordinal()),
        "Org " + status,
        "IN",
        status,
        null,
        null,
        0L);
  }

  @Test
  @DisplayName("refuses any role other than SUPER_ADMIN")
  void refusesNonSuperAdmin() {
    useCase = new GetPlatformHealthUseCase(directory);

    assertThatThrownBy(() -> useCase.execute("ORG_ADMIN"))
        .isInstanceOf(ResourceNotFoundException.class);
  }

  @Test
  @DisplayName("counts organizations by status")
  void countsOrganizationsByStatus() {
    useCase = new GetPlatformHealthUseCase(directory);
    when(directory.listAll())
        .thenReturn(
            List.of(
                organizationWithStatus(OrganizationStatus.ACTIVE),
                organizationWithStatus(OrganizationStatus.ACTIVE),
                organizationWithStatus(OrganizationStatus.SUSPENDED),
                organizationWithStatus(OrganizationStatus.CLOSED)));

    PlatformHealthSnapshot snapshot = useCase.execute("SUPER_ADMIN");

    assertThat(snapshot.databaseReachable()).isTrue();
    assertThat(snapshot.totalOrganizations()).isEqualTo(4);
    assertThat(snapshot.activeOrganizations()).isEqualTo(2);
    assertThat(snapshot.suspendedOrganizations()).isEqualTo(1);
    assertThat(snapshot.closedOrganizations()).isEqualTo(1);
  }

  @Test
  @DisplayName("reports unreachable rather than throwing when the directory read fails")
  void reportsUnreachableOnFailure() {
    useCase = new GetPlatformHealthUseCase(directory);
    when(directory.listAll()).thenThrow(new RuntimeException("boom"));

    PlatformHealthSnapshot snapshot = useCase.execute("SUPER_ADMIN");

    assertThat(snapshot.databaseReachable()).isFalse();
    assertThat(snapshot.totalOrganizations()).isZero();
  }
}
