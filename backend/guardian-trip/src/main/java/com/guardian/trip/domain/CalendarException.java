package com.guardian.trip.domain;

/**
 * How a school's calendar overrides the weekday pattern for one date (BR-TRIP-011).
 *
 * <p>Two directions, because a school calendar needs both: a holiday suppresses a day the routes
 * would otherwise run, and a working day enables one they would not. Without the second, running a
 * Saturday exam-day service would mean editing every route's operating days and remembering to
 * change them back.
 */
public enum CalendarException {
  /** The school does not operate on this date, whatever the weekday says. */
  HOLIDAY,

  /** The school operates on this date, whatever the weekday says. */
  WORKING_DAY
}
