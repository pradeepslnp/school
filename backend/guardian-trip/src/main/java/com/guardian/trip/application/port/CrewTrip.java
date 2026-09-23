package com.guardian.trip.application.port;

import com.guardian.trip.domain.Trip;
import java.util.UUID;

/**
 * One of the crew's runs, with the context the driver app needs to act on it.
 *
 * <p>A read record rather than a fatter {@link Trip}: the route's code and its expected vehicle are
 * not part of the trip aggregate — the vehicle in particular is deliberately <em>not</em> on the
 * trip until it starts (V5), because recording an intended bus as fact would misreport which one
 * carried the children.
 *
 * <p>The expected vehicle exists here for one reason: a {@code DRIVER} holds no {@code
 * PERM-VEHICLE-VIEW} (SystemRolePermissions), so the app cannot list buses to pick from. It shows
 * the one the route normally runs and asks the driver to confirm it. Confirming is still choosing —
 * the driver looks at the bus in front of them and taps, which is what BR-TRIP-004 asks for. It is
 * null when the route has no default vehicle, and the app must then say so rather than guess.
 */
public record CrewTrip(
    Trip trip,
    String routeCode,
    String routeName,
    String stopCount,
    UUID expectedVehicleId,
    String expectedVehicleDisplayName,
    String expectedVehicleRegistrationNo) {}
