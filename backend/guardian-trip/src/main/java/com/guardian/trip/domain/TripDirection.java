package com.guardian.trip.domain;

/**
 * Which leg of the school day a trip is (BR-TRIP-001).
 *
 * <p>Deliberately not "morning" and "afternoon": a school with two shifts runs a drop at midday,
 * and naming the concept after a clock rather than a direction of travel would make that
 * unrepresentable. The wire form is the enum name, matching
 * documentation/04-api/API_STANDARDS.md.
 */
public enum TripDirection {
  /** Home to school: children are collected at stops and alight at the school. */
  PICKUP,

  /** School to home: children board at the school and alight at their stop. */
  DROP
}
