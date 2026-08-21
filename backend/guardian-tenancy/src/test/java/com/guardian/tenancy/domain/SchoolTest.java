package com.guardian.tenancy.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.tenant.TenantId;
import java.time.ZoneId;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/** Domain unit tests — no Spring context, no database. */
class SchoolTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final OrganizationId ORG = OrganizationId.generate();

  private static School aSchool() {
    return School.create(
        TENANT,
        ORG,
        SchoolCode.of("GW-MAIN"),
        "Greenwood Main Campus",
        ZoneId.of("Asia/Kolkata"),
        Coordinates.of("28.6129", "77.2290"),
        GeofenceRadius.ofMetres(150));
  }

  @Test
  @DisplayName("a new school is active")
  void newSchoolIsActive() {
    assertThat(aSchool().isActive()).isTrue();
  }

  @Test
  @BusinessRule("BR-CFG-006")
  @DisplayName("timezone is required — it is never defaulted to server time")
  void timezoneIsRequired() {
    assertThatThrownBy(
            () ->
                School.create(
                    TENANT,
                    ORG,
                    SchoolCode.of("GW-MAIN"),
                    "Greenwood",
                    null,
                    Coordinates.of("28.6129", "77.2290"),
                    GeofenceRadius.ofMetres(150)))
        .isInstanceOf(NullPointerException.class)
        .hasMessageContaining("timezone");
  }

  @Test
  @DisplayName("name must not be blank")
  void nameMustNotBeBlank() {
    assertThatThrownBy(
            () ->
                School.create(
                    TENANT,
                    ORG,
                    SchoolCode.of("GW-MAIN"),
                    "   ",
                    ZoneId.of("Asia/Kolkata"),
                    Coordinates.of("28.6129", "77.2290"),
                    GeofenceRadius.ofMetres(150)))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.VALIDATION_REQUIRED_FIELD_MISSING);
  }

  @Test
  @BusinessRule("BR-TEN-003")
  @DisplayName("a school cannot be moved between organizations")
  void schoolCannotChangeOrganization() {
    School school = aSchool();

    assertThatThrownBy(() -> school.assertBelongsTo(OrganizationId.generate()))
        .isInstanceOf(BusinessRuleViolationException.class)
        .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
        .isEqualTo(ErrorCode.SCHOOL_CANNOT_CHANGE_ORGANIZATION);
  }

  @Test
  @DisplayName("reschedule replaces the timezone and nothing else")
  void rescheduleReplacesTimezoneOnly() {
    School original = aSchool();

    School rescheduled = original.reschedule(ZoneId.of("America/New_York"));

    assertThat(rescheduled.timezone()).isEqualTo(ZoneId.of("America/New_York"));
    assertThat(rescheduled.id()).isEqualTo(original.id());
    assertThat(rescheduled.location()).isEqualTo(original.location());
    assertThat(original.timezone()).isEqualTo(ZoneId.of("Asia/Kolkata"));
  }

  @Test
  @DisplayName("state changes return new instances; the original is untouched")
  void stateChangesAreImmutable() {
    School original = aSchool();

    School deactivated = original.deactivate();

    assertThat(original.isActive()).isTrue();
    assertThat(deactivated.isActive()).isFalse();
    assertThat(deactivated.id()).isEqualTo(original.id());
  }

  @Nested
  @DisplayName("SchoolCode")
  class SchoolCodeTest {

    @Test
    @BusinessRule("BR-TEN-007")
    void normalisesToUpperCase() {
      assertThat(SchoolCode.of(" gw-main ").value()).isEqualTo("GW-MAIN");
    }

    @Test
    void rejectsInvalidCharacters() {
      assertThatThrownBy(() -> SchoolCode.of("GW MAIN!"))
          .isInstanceOf(BusinessRuleViolationException.class);
    }

    @Test
    void rejectsSingleCharacter() {
      assertThatThrownBy(() -> SchoolCode.of("G"))
          .isInstanceOf(BusinessRuleViolationException.class);
    }
  }

  @Nested
  @DisplayName("GeofenceRadius")
  class GeofenceRadiusTest {

    @Test
    @BusinessRule({"BR-ROUTE-003", "BR-CFG-003"})
    @DisplayName("rejects a radius below the floor — GPS drift would never trigger arrival")
    void rejectsBelowFloor() {
      assertThatThrownBy(() -> GeofenceRadius.ofMetres(10))
          .isInstanceOf(BusinessRuleViolationException.class)
          .extracting(e -> ((BusinessRuleViolationException) e).errorCode())
          .isEqualTo(ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE);
    }

    @Test
    @BusinessRule({"BR-ROUTE-003", "BR-CFG-003"})
    @DisplayName("rejects a radius above the ceiling — geofences would overlap")
    void rejectsAboveCeiling() {
      assertThatThrownBy(() -> GeofenceRadius.ofMetres(5000))
          .isInstanceOf(BusinessRuleViolationException.class);
    }

    @Test
    void acceptsBoundaryValues() {
      assertThat(GeofenceRadius.ofMetres(GeofenceRadius.MIN_METRES).metres()).isEqualTo(20);
      assertThat(GeofenceRadius.ofMetres(GeofenceRadius.MAX_METRES).metres()).isEqualTo(2000);
    }
  }

  @Nested
  @DisplayName("Coordinates")
  class CoordinatesTest {

    @Test
    @BusinessRule("BR-TRACK-004")
    void rejectsOutOfRangeLatitude() {
      assertThatThrownBy(() -> Coordinates.of("91.0", "77.2290"))
          .isInstanceOf(BusinessRuleViolationException.class);
    }

    @Test
    @BusinessRule("BR-TRACK-004")
    void rejectsOutOfRangeLongitude() {
      assertThatThrownBy(() -> Coordinates.of("28.6129", "181.0"))
          .isInstanceOf(BusinessRuleViolationException.class);
    }

    @Test
    @DisplayName("scales to six decimal places so equality is reliable")
    void scalesConsistently() {
      assertThat(Coordinates.of("28.61290000", "77.229").latitude())
          .isEqualByComparingTo(Coordinates.of("28.6129", "77.229").latitude());
    }
  }
}
