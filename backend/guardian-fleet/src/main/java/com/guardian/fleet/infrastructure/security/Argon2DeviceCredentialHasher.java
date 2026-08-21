package com.guardian.fleet.infrastructure.security;

import com.guardian.fleet.application.port.DeviceCredentialHasher;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Argon2id, as SECURITY_ARCHITECTURE.md specifies for stored secrets.
 *
 * <p>{@link Argon2PasswordEncoder#matches} compares in constant time, which is why no comparison is
 * hand-written here.
 */
@Component
class Argon2DeviceCredentialHasher implements DeviceCredentialHasher {

  private final Argon2PasswordEncoder encoder =
      Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();

  @Override
  public String hash(String rawSecret) {
    return encoder.encode(rawSecret);
  }

  @Override
  public boolean matches(String rawSecret, String hash) {
    return encoder.matches(rawSecret, hash);
  }
}
