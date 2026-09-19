package com.guardian.infrastructure.staff;

import com.guardian.identity.application.command.ProvisionStaffAccountCommand;
import com.guardian.identity.application.usecase.ProvisionStaffAccountUseCase;
import com.guardian.staff.application.port.StaffAccountProvisioningPort;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.UserId;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Implements guardian-staff's {@link StaffAccountProvisioningPort} by calling guardian-identity's
 * {@link ProvisionStaffAccountUseCase} — this is the one place in the backend allowed to depend on
 * both modules, which is exactly why the port lives in guardian-staff and the adapter lives here
 * rather than the other way round. See the port's own documentation.
 *
 * <p>The only real work is translating between the two modules' own, parallel {@code UserId} types
 * (each wraps the same underlying UUID, deliberately kept distinct per module — see either type's
 * documentation) and choosing the role code/name a {@link StaffType} implies.
 */
@Component
class StaffAccountProvisioningAdapter implements StaffAccountProvisioningPort {

  private final ProvisionStaffAccountUseCase provisionStaffAccount;

  StaffAccountProvisioningAdapter(ProvisionStaffAccountUseCase provisionStaffAccount) {
    this.provisionStaffAccount = provisionStaffAccount;
  }

  @Override
  public UserId provision(
      StaffType staffType,
      String phone,
      String firstName,
      String lastName,
      UUID actorId,
      String actorRole) {

    var identityUserId =
        provisionStaffAccount.execute(
            new ProvisionStaffAccountCommand(
                phone,
                firstName,
                lastName,
                roleCodeFor(staffType),
                roleNameFor(staffType),
                actorId,
                actorRole));

    return UserId.of(identityUserId.value());
  }

  /**
   * The role code PERMISSION_MATRIX.md gives each staff type — matches V900's seeded DRIVER role.
   */
  static String roleCodeFor(StaffType staffType) {
    return staffType.name();
  }

  private static String roleNameFor(StaffType staffType) {
    return switch (staffType) {
      case DRIVER -> "Driver";
      case ATTENDANT -> "Attendant";
    };
  }
}
