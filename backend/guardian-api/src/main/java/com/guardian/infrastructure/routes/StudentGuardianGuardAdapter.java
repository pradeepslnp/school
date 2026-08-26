package com.guardian.infrastructure.routes;

import com.guardian.guardian.application.port.GuardianRepository;
import com.guardian.routes.application.port.StudentGuardianGuard;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Implements guardian-routes' {@link StudentGuardianGuard} by asking guardian-guardian's {@link
 * GuardianRepository} — the one place allowed to depend on both modules, which is why the port
 * lives in guardian-routes and this adapter lives in the composition root. Same shape as {@code
 * StaffAccountProvisioningAdapter} and {@code GuardianAccountProvisioningAdapter}.
 */
@Component
class StudentGuardianGuardAdapter implements StudentGuardianGuard {

  private final GuardianRepository guardians;

  StudentGuardianGuardAdapter(GuardianRepository guardians) {
    this.guardians = guardians;
  }

  @Override
  public boolean hasActiveHandoverGuardian(UUID studentId) {
    return guardians.hasActiveHandoverGuardian(studentId);
  }
}
