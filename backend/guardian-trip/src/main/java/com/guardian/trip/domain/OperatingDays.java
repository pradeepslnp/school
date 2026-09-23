package com.guardian.trip.domain;

import java.time.DayOfWeek;
import java.util.EnumSet;
import java.util.Locale;
import java.util.Set;

/**
 * The days of the week a route runs (BR-TRIP-011).
 *
 * <p>Parsed from the {@code routes.operating_days} column, which stores a comma-separated list of
 * three-letter codes ({@code MON,TUE,WED,THU,FRI}). The column is legible in a psql session during
 * an incident, which is worth more here than the compactness of a bitmask.
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
}
