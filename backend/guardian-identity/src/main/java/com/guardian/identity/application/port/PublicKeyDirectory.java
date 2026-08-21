package com.guardian.identity.application.port;

import java.util.Map;

/**
 * Publishes the public half of the token signing keys.
 *
 * <p>A port so the JWKS controller never reaches into infrastructure — signing, key parsing, and
 * rotation are implementation details, and an architecture test fails the build for an {@code
 * interfaces} class that depends on {@code infrastructure}.
 *
 * <p>Returned as a plain map because the shape is fixed by RFC 7517, not by this platform. A DTO
 * would be this codebase re-describing somebody else's specification and drifting from it.
 */
public interface PublicKeyDirectory {

  /**
   * The JWK Set.
   *
   * <p>Contains the current signing key <strong>and</strong> the previous one during rotation, so
   * tokens signed a moment before a key change stay verifiable for their remaining lifetime instead
   * of every client being signed out at once.
   *
   * <p>Implementations must publish public keys only.
   */
  Map<String, Object> publicJwkSet();
}
