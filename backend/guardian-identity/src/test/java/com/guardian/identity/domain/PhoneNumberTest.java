package com.guardian.identity.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class PhoneNumberTest {

  @Test
  @DisplayName("the same subscriber typed three ways normalises to one value")
  void normalisesEquivalentForms() {
    PhoneNumber international = PhoneNumber.of("+91 80506 02046");
    PhoneNumber national = PhoneNumber.of("08050602046");
    PhoneNumber bare = PhoneNumber.of("8050602046");

    // This is the whole reason the type exists. If these diverged, a parent who typed their
    // number a different way at the next sign-in would fail to be recognised — or, worse,
    // would be matched to a second row and see none of their children.
    assertThat(national).isEqualTo(bare);
    assertThat(international.value()).isEqualTo("918050602046");
  }

  @Test
  @DisplayName("punctuation and spacing are irrelevant")
  void stripsNonDigits() {
    assertThat(PhoneNumber.of("(805) 060-2046").value()).isEqualTo("8050602046");
  }

  @Test
  @DisplayName("too few or too many digits is not a phone number")
  void rejectsImplausibleLengths() {
    assertThatThrownBy(() -> PhoneNumber.of("12345")).isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> PhoneNumber.of("1234567890123456789"))
        .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  @DisplayName("neither masked() nor toString() discloses the number")
  void neverRendersInFull() {
    PhoneNumber phone = PhoneNumber.of("8050602046");

    assertThat(phone.masked()).isEqualTo("******2046");
    // toString is asserted separately because it is the one that ends up in a log by accident,
    // via string concatenation nobody reviewed. A full mobile number in a log identifies a
    // family at a named school.
    assertThat(phone.toString()).doesNotContain("8050602046");
  }
}
