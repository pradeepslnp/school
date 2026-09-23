package com.guardian.trip.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.DayOfWeek;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Parsing is where a typo becomes a route that silently stops running, so the strictness is the
 * behaviour under test, not an implementation detail.
 */
class OperatingDaysTest {

  @Test
  @DisplayName("the five-day school week parses to exactly those days")
  void parsesWeekdays() {
    OperatingDays days = OperatingDays.parse("MON,TUE,WED,THU,FRI");

    assertThat(days.includes(DayOfWeek.MONDAY)).isTrue();
    assertThat(days.includes(DayOfWeek.FRIDAY)).isTrue();
    assertThat(days.includes(DayOfWeek.SATURDAY)).isFalse();
    assertThat(days.includes(DayOfWeek.SUNDAY)).isFalse();
  }

  @Test
  @DisplayName("whitespace, case and order do not change the meaning")
  void parsingIsLenientAboutShape() {
    OperatingDays days = OperatingDays.parse(" sat , mon ");

    assertThat(days.includes(DayOfWeek.MONDAY)).isTrue();
    assertThat(days.includes(DayOfWeek.SATURDAY)).isTrue();
    assertThat(days.asSet()).hasSize(2);
  }

  @Test
  @DisplayName("an unrecognised code throws rather than being skipped")
  void rejectsUnknownCode() {
    assertThatThrownBy(() -> OperatingDays.parse("MON,TEU"))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("TEU");
  }

  @Test
  @DisplayName("null or blank means a route that runs on no day, not a route that runs always")
  void emptyMeansNoDays() {
    assertThat(OperatingDays.parse(null).isEmpty()).isTrue();
    assertThat(OperatingDays.parse("  ").isEmpty()).isTrue();
    assertThat(OperatingDays.parse(null).includes(DayOfWeek.MONDAY)).isFalse();
  }
}
