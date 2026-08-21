package com.guardian.identity.domain;

import java.time.Instant;
import java.util.Objects;

/**
 * A person who can hold a session.
 *
 * <p>Guardians are created by their school, not by signing in: {@code POST /auth/otp/request} looks
 * a person up, it never creates one. That is deliberate and is the reason the login screen says
 * "the mobile number registered with your school". A flow that created an account for any number
 * that completed an OTP would let anybody with a working handset appear in a tenant's user table,
 * and being in that table is the first half of being linked to a child.
 *
 * <p>Roles are not held here. They are resolved per request from {@code user_roles} so a change
 * takes effect on the next call rather than at token expiry (BR-IAM-004).
 */
public final class User {

  private final UserId id;
  private final PhoneNumber phone;
  private final String email;
  private final String firstName;
  private final String lastName;
  private final String preferredLocale;
  private final UserStatus status;
  private final Instant lastLoginAt;
  private final long version;

  private User(
      UserId id,
      PhoneNumber phone,
      String email,
      String firstName,
      String lastName,
      String preferredLocale,
      UserStatus status,
      Instant lastLoginAt,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.phone = phone;
    this.email = email;
    this.firstName = Objects.requireNonNull(firstName, "firstName");
    this.lastName = Objects.requireNonNull(lastName, "lastName");
    this.preferredLocale = Objects.requireNonNull(preferredLocale, "preferredLocale");
    this.status = Objects.requireNonNull(status, "status");
    this.lastLoginAt = lastLoginAt;
    this.version = version;
  }

  public static User rehydrate(
      UserId id,
      PhoneNumber phone,
      String email,
      String firstName,
      String lastName,
      String preferredLocale,
      UserStatus status,
      Instant lastLoginAt,
      long version) {
    return new User(
        id, phone, email, firstName, lastName, preferredLocale, status, lastLoginAt, version);
  }

  /**
   * A brand-new, active user with a phone but no email — the shape staff provisioning needs
   * (feature STF-001/MOD-02). Guardians are never created this way (see this class's own
   * documentation); this factory exists for the one path that does create an account directly: a
   * school registering a driver or attendant who is then handed a working sign-in.
   */
  public static User create(
      UserId id, PhoneNumber phone, String firstName, String lastName, String preferredLocale) {
    return new User(
        id,
        Objects.requireNonNull(phone, "phone"),
        null,
        firstName,
        lastName,
        preferredLocale,
        UserStatus.ACTIVE,
        null,
        0L);
  }

  /** Records a successful sign-in. */
  public User signedInAt(Instant now) {
    return new User(id, phone, email, firstName, lastName, preferredLocale, status, now, version);
  }

  public UserId id() {
    return id;
  }

  public PhoneNumber phone() {
    return phone;
  }

  public String email() {
    return email;
  }

  public String firstName() {
    return firstName;
  }

  public String lastName() {
    return lastName;
  }

  public String preferredLocale() {
    return preferredLocale;
  }

  public UserStatus status() {
    return status;
  }

  public Instant lastLoginAt() {
    return lastLoginAt;
  }

  public long version() {
    return version;
  }

  /** Excludes the phone number and email — both identify a family at a named school. */
  @Override
  public String toString() {
    return "User[id=" + id + ", status=" + status + "]";
  }
}
