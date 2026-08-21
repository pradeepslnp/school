package com.guardian.identity.infrastructure.security;

import com.guardian.identity.application.port.PublicKeyDirectory;
import java.util.Map;
import org.springframework.stereotype.Component;

/** Serialises the published key set. */
@Component
class NimbusPublicKeyDirectory implements PublicKeyDirectory {

  private final RsaSigningKeys keys;

  NimbusPublicKeyDirectory(RsaSigningKeys keys) {
    this.keys = keys;
  }

  @Override
  public Map<String, Object> publicJwkSet() {
    // toJSONObject() on a JWKSet emits public parameters only; the private half of a key is
    // never included even when the JWKSet was built from one. The set here is already built
    // from toPublicJWK() copies, so this is the second of two independent reasons no private
    // key can reach the endpoint.
    return keys.publicKeys().toJSONObject();
  }
}
