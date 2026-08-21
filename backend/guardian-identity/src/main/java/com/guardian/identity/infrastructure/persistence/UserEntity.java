package com.guardian.identity.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/**
 * JPA mapping for {@code users}.
 *
 * <p>Never leaves this package — an architecture test fails the build if a controller returns one.
 * Mapping to and from {@link com.guardian.identity.domain.User} is explicit and lossy on purpose:
 * the domain has no {@code createdBy}, and the entity has no behaviour.
 */
@Entity
@Table(name = "users")
public class UserEntity {

  @Id
  @Column(name = "id", nullable = false, updatable = false)
  private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false)
  private UUID tenantId;

  @Column(name = "email")
  private String email;

  @Column(name = "phone", length = 32)
  private String phone;

  @Column(name = "first_name", nullable = false, length = 128)
  private String firstName;

  @Column(name = "last_name", nullable = false, length = 128)
  private String lastName;

  @Column(name = "preferred_locale", nullable = false, length = 16)
  private String preferredLocale;

  @Column(name = "status", nullable = false, length = 24)
  private String status;

  @Column(name = "last_login_at")
  private Instant lastLoginAt;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Version
  @Column(name = "version", nullable = false)
  private long version;

  protected UserEntity() {
    // required by JPA
  }

  /** A brand-new row (feature STF-001/MOD-02) — see {@code UserRepository.create}. */
  UserEntity(
      UUID id,
      UUID tenantId,
      String email,
      String phone,
      String firstName,
      String lastName,
      String preferredLocale,
      String status) {
    this.id = id;
    this.tenantId = tenantId;
    this.email = email;
    this.phone = phone;
    this.firstName = firstName;
    this.lastName = lastName;
    this.preferredLocale = preferredLocale;
    this.status = status;
    Instant now = Instant.now();
    this.createdAt = now;
    this.updatedAt = now;
  }

  /**
   * Records a sign-in. The only mutation this entity permits — every other field is owned by
   * whoever administers the user, not by the authentication flow.
   */
  void applySignIn(Instant lastLoginAt) {
    this.lastLoginAt = lastLoginAt;
    this.updatedAt = Instant.now();
  }

  UUID getId() {
    return id;
  }

  UUID getTenantId() {
    return tenantId;
  }

  String getEmail() {
    return email;
  }

  String getPhone() {
    return phone;
  }

  String getFirstName() {
    return firstName;
  }

  String getLastName() {
    return lastName;
  }

  String getPreferredLocale() {
    return preferredLocale;
  }

  String getStatus() {
    return status;
  }

  Instant getLastLoginAt() {
    return lastLoginAt;
  }

  long getVersion() {
    return version;
  }
}
