package com.guardian.guardian.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.guardian.application.port.PickupPersonRepository;
import com.guardian.guardian.domain.PickupPerson;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Active nominations for one child (feature GRD-004).
 *
 * <p>Gated on being a linked guardian, not on holding the handover right: a parent who cannot
 * nominate can still legitimately see who is authorised to collect their child. Reading the list
 * and adding to it are different acts, and conflating them would hide safety-relevant information
 * from a guardian entitled to it.
 */
@Service
public class ListPickupPersonsUseCase {

  private final PickupPersonRepository pickupPersons;

  public ListPickupPersonsUseCase(PickupPersonRepository pickupPersons) {
    this.pickupPersons = pickupPersons;
  }

  @Transactional(readOnly = true)
  public List<PickupPerson> execute(UUID actorUserId, UUID studentId) {
    if (!pickupPersons.isLinkedGuardian(actorUserId, studentId)) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "student", studentId);
    }
    return pickupPersons.findActiveForStudent(studentId);
  }
}
