package com.guardian.tenancy.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/** Domain unit tests — no Spring context, no database. Mirrors {@code SchoolTest}. */
class OrganizationTest {

  private static Organization anOrganization() {
    return Organization.create(
        OrganizationCode.of("GREENWOOD"),
        "Greenwood Education Group",
        "IN",
        "ops@greenwood.example",
        "+919876543210");
  }

  @Test
  @BusinessRule("BR-TEN-001")
  @DisplayName("a new organization is active")
  void newOrganizationIsActive() {
    assertThat(anOrganization().status()).isEqualTo(OrganizationStatus.ACTIVE);
  }

  @Test
  @BusinessRule("BR-TEN-001")
  @DisplayName("name must not be blank")
  void nameMustNotBeBlank() {
    assertThatThrownBy(
            () -> Organization.create(OrganizationCode.of("GREENWOOD"), "   ", "IN", null, null))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING);
  }

  @Test
  @BusinessRule("BR-TEN-001")
  @DisplayName("region profile code is required and never defaulted (ADR-0007)")
  void regionProfileCodeIsRequired() {
    assertThatThrownBy(
            () ->
                Organization.create(OrganizationCode.of("GREENWOOD"), "Greenwood", " ", null, null))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING);
  }

  @Test
  @DisplayName("contact details are optional")
  void contactDetailsAreOptional() {
    Organization organization =
        Organization.create(OrganizationCode.of("GREENWOOD"), "Greenwood", "IN", null, null);

    assertThat(organization.contactEmail()).isNull();
    assertThat(organization.contactPhone()).isNull();
  }

  @Test
  @DisplayName("update replaces name, region, and contact details but not code, id, or status")
  void updateReplacesEditableFieldsOnly() {
    Organization original = anOrganization();

    Organization updated =
        original.update("Greenwood Group Renamed", "US", "new@greenwood.example", "+15551234567");

    assertThat(updated.id()).isEqualTo(original.id());
    assertThat(updated.code()).isEqualTo(original.code());
    assertThat(updated.status()).isEqualTo(original.status());
    assertThat(updated.name()).isEqualTo("Greenwood Group Renamed");
    assertThat(updated.regionProfileCode()).isEqualTo("US");
    assertThat(updated.contactEmail()).isEqualTo("new@greenwood.example");
    assertThat(updated.contactPhone()).isEqualTo("+15551234567");
    // The original is untouched — matches School.stateChangesAreImmutable.
    assertThat(original.name()).isEqualTo("Greenwood Education Group");
  }

  @Test
  @BusinessRule("BR-TEN-001")
  @DisplayName("update refuses a blank name, same as create")
  void updateRejectsBlankName() {
    Organization original = anOrganization();

    assertThatThrownBy(() -> original.update("  ", "IN", null, null))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING);
  }

  @Nested
  @DisplayName("OrganizationCode")
  class OrganizationCodeTest {

    @Test
    @BusinessRule("BR-TEN-007")
    @DisplayName("normalises to upper case, unlike a school code scoped to one organization")
    void normalisesToUpperCase() {
      assertThat(OrganizationCode.of(" greenwood ").value()).isEqualTo("GREENWOOD");
    }

    @Test
    @BusinessRule("BR-TEN-007")
    void rejectsInvalidCharacters() {
      assertThatThrownBy(() -> OrganizationCode.of("GREEN WOOD!"))
          .isInstanceOf(BusinessRuleViolationException.class);
    }

    @Test
    @BusinessRule("BR-TEN-007")
    void rejectsSingleCharacter() {
      assertThatThrownBy(() -> OrganizationCode.of("G"))
          .isInstanceOf(BusinessRuleViolationException.class);
    }
  }
}
