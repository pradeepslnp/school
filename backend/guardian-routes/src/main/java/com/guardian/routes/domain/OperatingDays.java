package com.guardian.routes.domain;

import java.time.DayOfWeek;
import java.util.EnumSet;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * The days of the week a route runs (BR-TRIP-011).
 *
 * <p>Held on {@link Route} and stored in the {@code routes.operating_days} column as a
 * comma-separated list of three-letter codes ({@code MON,TUE,WED,THU,FRI}). The column is legible
 * in a psql session during an incident, which is worth more here than the compactness of a bitmask.
 *
 * <p>MOD-08 does not parse it: trip generation matches the weekday in SQL, against the same column.
 * This type exists so the value is validated and normalised on the way <em>in</em> — the only place
 * a bad one can be introduced.
 *
 * <p>Parsing is lenient about whitespace, case, and order, and strict about everything else: an
 * unrecognised token throws rather than being skipped. A silently ignored {@code "TEU"} typo would
 * produce a route that quietly stops running on Tuesdays, and the first person to notice would be a
 * parent whose child was left at a stop.
 */
public final class OperatingDays {

  private final Set<DayOfWeek> days;

  private OperatingDays(Set<DayOfWeek> days) {
    this.days = days;
  }

  /**
   * Parses the stored column value.
   *
   * @throws IllegalArgumentException if a token is not one of the seven day codes. Null or blank
   *     yields an empty set — a route that runs on no day, which generation simply skips.
   */
  public static OperatingDays parse(String stored) {
    EnumSet<DayOfWeek> parsed = EnumSet.noneOf(DayOfWeek.class);
    if (stored == null || stored.isBlank()) {
      return new OperatingDays(parsed);
    }

    for (String token : stored.split(",")) {
      String code = token.trim().toUpperCase(Locale.ROOT);
      if (code.isEmpty()) {
        continue;
      }
      parsed.add(toDayOfWeek(code));
    }
    return new OperatingDays(parsed);
  }

  private static DayOfWeek toDayOfWeek(String code) {
    return switch (code) {
      case "MON" -> DayOfWeek.MONDAY;
      case "TUE" -> DayOfWeek.TUESDAY;
      case "WED" -> DayOfWeek.WEDNESDAY;
      case "THU" -> DayOfWeek.THURSDAY;
      case "FRI" -> DayOfWeek.FRIDAY;
      case "SAT" -> DayOfWeek.SATURDAY;
      case "SUN" -> DayOfWeek.SUNDAY;
      default -> throw new IllegalArgumentException("unrecognised operating day code: " + code);
    };
  }

  public boolean includes(DayOfWeek day) {
    return days.contains(day);
  }

  public boolean isEmpty() {
    return days.isEmpty();
  }

  public Set<DayOfWeek> asSet() {
    return EnumSet.copyOf(days.isEmpty() ? EnumSet.noneOf(DayOfWeek.class) : days);
  }

  /**
   * The value written to {@code routes.operating_days}.
   *
   * <p>Always in calendar order, whatever order the caller supplied, so two routes that run the
   * same days store the same string. A column whose value depends on the order a form's checkboxes
   * were ticked is a column that cannot be compared or grouped.
   */
  public String toStoredValue() {
    return days.stream().map(OperatingDays::toCode).collect(Collectors.joining(","));
  }

  private static String toCode(DayOfWeek day) {
    return switch (day) {
      case MONDAY -> "MON";
      case TUESDAY -> "TUE";
      case WEDNESDAY -> "WED";
      case THURSDAY -> "THU";
      case FRIDAY -> "FRI";
      case SATURDAY -> "SAT";
      case SUNDAY -> "SUN";
    };
  }

  /**
   * The five-day school week — what a route runs unless someone says otherwise.
   *
   * <p>Used as the default when a caller does not state operating days, matching the column
   * default so a route created through the API and one created by the migration agree.
   */
  public static OperatingDays schoolWeek() {
    return parse("MON,TUE,WED,THU,FRI");
  }

  @Override
  public boolean equals(Object other) {
    return other instanceof OperatingDays operatingDays && days.equals(operatingDays.days);
  }

  @Override
  public int hashCode() {
    return days.hashCode();
  }

  @Override
  public String toString() {
    return toStoredValue();
  }
}
