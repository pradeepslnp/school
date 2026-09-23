package com.guardian.trip.application.port;

import java.util.Optional;
import java.util.UUID;

/**
 * Resolves the transport-staff record behind an authenticated user (MOD-06's data, MOD-08's
 * question).
 *
 * <p>A driver signs in as a {@code users} row; the roster, the eligibility rules and the duty
 * assignments all key on {@code transport_staff}. Something has to bridge the two, and it is a
 * lookup rather than a rule — which is why it is a narrow read port here instead of a dependency on
 * a MOD-06 use case.
 *
 * <p>Empty means the caller is not crew: a transport manager, an administrator, or a staff record
 * that was never linked to a login. That is a legitimate state, not an error — BR-TRIP-006 lets a
 * transport manager start a trip they are not rostered for.
 */
public interface CrewDirectory {

  Optional<UUID> staffIdForUser(UUID userId);
}
