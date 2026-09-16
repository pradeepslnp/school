package com.guardian.search.domain;

/**
 * The kinds of record global search returns (SRC-001), in the order results are grouped.
 *
 * <p>People an operator is most often looking for come first — a child, then the adults around them
 * — and the structural records after.
 */
public enum SearchResultType {
  STUDENT,
  GUARDIAN,
  STAFF,
  VEHICLE,
  ROUTE,
  USER,
  SCHOOL,
  ORGANIZATION
}
