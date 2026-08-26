package com.guardian.guardian.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * A parent or other adult with a standing relationship to one or more students (MOD-04, GRD-001).
 *
 * <p>A guardian is a <em>record</em> first and an account second: {@code userId} is the sign-in it
 * is tied to. In this platform's enrolment flow the account is provisioned the moment the guardian
 * is created, so {@code userId} is normally set — but it stays nullable because the schema allows a
 * guardian to exist before ever activating a login ({@code guardians.user_id} is nullable), and a
 * record imported from elsewhere may not have one.
 *
 * <p>One guardian record, many children: a parent of siblings is a single {@link Guardian} linked
 * to each child through {@code guardian_student_links}, never duplicated per child. That is why the
 * rights that decide "may this adult collect this student" live on the link, not here — see {@link
 * GuardianStudentLink}.
 */
public record Guardian(
    UUID id,
    UUID userId,
    String firstName,
    String lastName,
    String phone,
    String email,
    boolean active) {

  public Guardian {
    Objects.requireNonNull(firstName, "firstName");
    Objects.requireNonNull(lastName, "lastName");
    Objects.requireNonNull(phone, "phone");
  }

  public String displayName() {
    return (firstName + " " + lastName).trim();
  }

  public boolean hasLogin() {
    return userId != null;
  }
}
