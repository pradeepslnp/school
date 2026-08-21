package com.guardian.identity.interfaces.rest;

import com.guardian.common.rest.RawResponseBody;
import com.guardian.common.security.PublicEndpoint;
import com.guardian.identity.application.port.PublicKeyDirectory;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Publishes the token signing keys (ADR-0006).
 *
 * <p>Public by definition: a verifier that had to authenticate to fetch the key it needs in order
 * to verify authentication has a chicken-and-egg problem. Nothing secret is served — the private
 * half never leaves the signing key.
 */
@RestController
public class JwksController {

  private final PublicKeyDirectory publicKeys;

  public JwksController(PublicKeyDirectory publicKeys) {
    this.publicKeys = publicKeys;
  }

  @GetMapping("/.well-known/jwks.json")
  @PublicEndpoint(reason = "public verification keys; a verifier cannot authenticate to fetch them")
  @RawResponseBody(reason = "RFC 7517 fixes the JWK Set shape; an envelope makes it unparseable")
  public Map<String, Object> jwks() {
    return publicKeys.publicJwkSet();
  }
}
