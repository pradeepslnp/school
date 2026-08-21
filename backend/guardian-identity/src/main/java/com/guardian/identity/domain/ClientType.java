package com.guardian.identity.domain;

import java.time.Duration;

/**
 * Which application holds the session.
 *
 * <p>Refresh lifetime is a property of the client, not a global setting. A guardian losing their
 * session mid-emergency is itself a safety problem, so the parent app gets the longest one; a
 * driver's handset is often shared and changes hands between shifts, so it gets the shortest
 * (guardian-docs/02-system-design/SECURITY_ARCHITECTURE.md).
 */
public enum ClientType {
  PARENT_APP(Duration.ofDays(90)),
  DRIVER_APP(Duration.ofDays(7)),
  ADMIN_WEB(Duration.ofDays(14));

  private final Duration refreshLifetime;

  ClientType(Duration refreshLifetime) {
    this.refreshLifetime = refreshLifetime;
  }

  public Duration refreshLifetime() {
    return refreshLifetime;
  }

  /**
   * Parses a client-supplied value.
   *
   * @throws IllegalArgumentException for an unknown client — an unrecognised client type is never
   *     defaulted, because the default would decide how long a stolen token stays usable
   */
  public static ClientType fromWire(String value) {
    for (ClientType type : values()) {
      if (type.name().equalsIgnoreCase(value)) {
        return type;
      }
    }
    throw new IllegalArgumentException("unknown client type");
  }
}
