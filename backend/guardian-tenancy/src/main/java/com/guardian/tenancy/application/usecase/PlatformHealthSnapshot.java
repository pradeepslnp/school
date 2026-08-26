package com.guardian.tenancy.application.usecase;

import java.time.Instant;

/**
 * A point-in-time pulse check for the Platform health screen (A-62).
 *
 * <p>Deliberately not infrastructure telemetry — no heap, disk, or request-rate metrics. Nothing
 * in this platform collects those today, and a platform operator (Deepak, PERSONAS.md) has no use
 * for JVM internals when they open this screen: what they need to know is "is the platform
 * basically working" and "how many tenants would notice if it were not". {@link
 * #databaseReachable} answers the first as a best-effort signal (see {@code
 * GetPlatformHealthUseCase}'s Javadoc for why it is best-effort, not a guarantee); the
 * organization counts answer the second.
 */
public record PlatformHealthSnapshot(
    boolean databaseReachable,
    int totalOrganizations,
    int activeOrganizations,
    int suspendedOrganizations,
    int closedOrganizations,
    Instant checkedAt) {}
