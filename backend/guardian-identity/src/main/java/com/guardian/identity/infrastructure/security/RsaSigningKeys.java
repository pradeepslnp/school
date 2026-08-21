package com.guardian.identity.infrastructure.security;

import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * The RSA keys access tokens are signed with, and the public set published at the JWKS endpoint.
 *
 * <h2>Rotation</h2>
 *
 * <p>One key signs; the JWKS publishes the signing key <em>and</em> the previous one. That overlap
 * is what makes rotation a non-event: tokens signed by the outgoing key stay verifiable for their
 * remaining fifteen minutes instead of every client being logged out the moment a key changes.
 * Rotating without the overlap is the classic way to turn key rotation into an outage.
 *
 * <h2>The development fallback, and why it cannot reach production</h2>
 *
 * <p>With no key configured this generates an ephemeral pair at startup so a developer can run the
 * stack with no setup. Every restart invalidates every token, which is correct for a laptop and
 * catastrophic anywhere else — a rolling deploy across two instances would have them signing with
 * different keys and rejecting each other's tokens.
 *
 * <p>So the gate is <strong>structural, not advisory</strong>: a production profile with no
 * configured key fails startup. The instance never comes up, rather than coming up and silently
 * issuing tokens that die at the next deploy.
 */
@Component
public class RsaSigningKeys {

  private static final Logger log = LoggerFactory.getLogger(RsaSigningKeys.class);

  private static final int GENERATED_KEY_SIZE = 2048;

  private final RSAKey signingKey;
  private final JWKSet publicKeys;

  RsaSigningKeys(
      @Value("${guardian.security.jwt.private-key:}") String privateKeyPem,
      @Value("${guardian.security.jwt.public-key:}") String publicKeyPem,
      @Value("${guardian.security.jwt.key-id:}") String keyId,
      @Value("${guardian.security.jwt.previous-public-key:}") String previousPublicKeyPem,
      @Value("${guardian.security.jwt.previous-key-id:}") String previousKeyId,
      Environment environment) {

    boolean configured = !privateKeyPem.isBlank() && !publicKeyPem.isBlank();

    if (!configured) {
      requireNonProduction(environment);
      this.signingKey = generateEphemeralKey();
      log.warn(
          "No JWT signing key configured; generated an ephemeral one. Every restart invalidates"
              + " every access token. Set guardian.security.jwt.private-key outside development.");
    } else {
      this.signingKey =
          new RSAKey.Builder(parsePublicKey(publicKeyPem))
              .privateKey(parsePrivateKey(privateKeyPem))
              .keyID(keyId.isBlank() ? "guardian-signing-key" : keyId)
              .build();
    }

    List<com.nimbusds.jose.jwk.JWK> published = new ArrayList<>();
    // toPublicJWK strips the private half. Publishing the full key at the JWKS endpoint would
    // hand out the platform's signing key, so this call is not optional decoration.
    published.add(this.signingKey.toPublicJWK());

    if (!previousPublicKeyPem.isBlank()) {
      published.add(
          new RSAKey.Builder(parsePublicKey(previousPublicKeyPem))
              .keyID(previousKeyId.isBlank() ? "guardian-previous-key" : previousKeyId)
              .build()
              .toPublicJWK());
    }

    this.publicKeys = new JWKSet(published);
  }

  /** The key to sign with. Includes the private half — never serialise this. */
  public RSAKey signingKey() {
    return signingKey;
  }

  /** Public keys only, for {@code GET /.well-known/jwks.json}. */
  public JWKSet publicKeys() {
    return publicKeys;
  }

  private static void requireNonProduction(Environment environment) {
    boolean production =
        List.of(environment.getActiveProfiles()).stream()
            .anyMatch(
                profile ->
                    profile.equalsIgnoreCase("prod") || profile.equalsIgnoreCase("production"));

    if (production) {
      throw new IllegalStateException(
          "guardian.security.jwt.private-key is required in production: an ephemeral key would"
              + " be different on every instance and invalidate every token on each deploy");
    }
  }

  private static RSAKey generateEphemeralKey() {
    try {
      KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
      generator.initialize(GENERATED_KEY_SIZE);
      KeyPair pair = generator.generateKeyPair();

      return new RSAKey.Builder((RSAPublicKey) pair.getPublic())
          .privateKey((RSAPrivateKey) pair.getPrivate())
          // A fresh id per boot, so a client that cached the previous JWKS gets a miss rather
          // than a stale key under a familiar name.
          .keyID("ephemeral-" + UUID.randomUUID())
          .build();
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException("RSA unavailable", e);
    }
  }

  private static RSAPublicKey parsePublicKey(String pem) {
    try {
      return (RSAPublicKey)
          KeyFactory.getInstance("RSA").generatePublic(new X509EncodedKeySpec(decode(pem)));
    } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
      throw new IllegalStateException("guardian.security.jwt.public-key is not a valid key", e);
    }
  }

  private static RSAPrivateKey parsePrivateKey(String pem) {
    try {
      return (RSAPrivateKey)
          KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(decode(pem)));
    } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
      // Deliberately does not echo the value. A misconfigured private key must not appear in
      // a startup log, which is usually the least protected place a secret can land.
      throw new IllegalStateException(
          "guardian.security.jwt.private-key is not a valid PKCS#8 key", e);
    }
  }

  /** Accepts a PEM block or bare base64, with or without line breaks. */
  private static byte[] decode(String pem) {
    String body =
        pem.replaceAll("-----BEGIN (.*)-----", "")
            .replaceAll("-----END (.*)-----", "")
            .replaceAll("\\s", "");
    return Base64.getDecoder().decode(body);
  }
}
