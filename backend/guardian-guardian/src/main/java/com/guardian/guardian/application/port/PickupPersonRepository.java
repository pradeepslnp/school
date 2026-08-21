package com.guardian.guardian.application.port;

import com.guardian.guardian.domain.PickupPerson;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistence for authorised pickup persons and the guardian rights that gate them. */
public interface PickupPersonRepository {

  /** Active nominations for a student, soonest to expire first. */
  List<PickupPerson> findActiveForStudent(UUID studentId);

  PickupPerson save(PickupPerson person, UUID actorUserId);

  /** Marks a nomination revoked. Immediate (BR-GRD-007); never a delete. */
  void revoke(UUID pickupPersonId, UUID actorUserId);

  Optional<PickupPerson> findById(UUID pickupPersonId);

  /**
   * The guardian id for this user on this student, only when they hold {@code
   * can_authorise_handover}.
   *
   * <p>This is BR-GRD-006 expressed as a lookup. Empty means either "not your child" or "you do not
   * hold the handover right" — the caller turns both into the same refusal, because telling them
   * apart would confirm a child exists at this school.
   */
  Optional<UUID> nominatingGuardianIdFor(UUID userId, UUID studentId);

  /** Whether the user is an active guardian of this student at all, with view rights. */
  boolean isLinkedGuardian(UUID userId, UUID studentId);
}
