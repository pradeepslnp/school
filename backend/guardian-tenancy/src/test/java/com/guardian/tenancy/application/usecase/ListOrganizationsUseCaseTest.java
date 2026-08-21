package com.guardian.tenancy.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.guardian.common.error.ErrorCode;
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

/** Unit tests for the use case. Port is mocked; no Spring context, no database. */
@ExtendWith(MockitoExtension.class)
class ListOrganizationsUseCaseTest {

  @Mock private PlatformOrganizationDirectory directory;

  private static Organization organization(String name) {
    return new Organization(
        OrganizationId.generate(),
        OrganizationCode.of("GREENWOOD"),
        name,
        "IN",
        OrganizationStatus.ACTIVE,
        null,
        null,
        0L);
  }

  @Test
  @DisplayName("a SUPER_ADMIN receives every organization the directory returns")
  void superAdminReceivesTheFullList() {
    when(directory.listAll())
        .thenReturn(
            List.of(organization("Greenwood Education Group"), organization("Oakridge Schools")));

    ListOrganizationsUseCase useCase = new ListOrganizationsUseCase(directory);

    List<Organization> result = useCase.execute("SUPER_ADMIN");

    assertThat(result).hasSize(2);
  }

  @Test
  @DisplayName(
      "any role other than SUPER_ADMIN is refused with AUTH_SCOPE_DENIED, before the directory is read")
  void nonSuperAdminIsRefused() {
    ListOrganizationsUseCase useCase = new ListOrganizationsUseCase(directory);

    assertThatThrownBy(() -> useCase.execute("ORG_ADMIN"))
        .isInstanceOf(ResourceNotFoundException.class)
        .extracting(e -> ((ResourceNotFoundException) e).errorCode())
        .isEqualTo(ErrorCode.AUTH_SCOPE_DENIED);

    verifyNoInteractions(directory);
  }
}
