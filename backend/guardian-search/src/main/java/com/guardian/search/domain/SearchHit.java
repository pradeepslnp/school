package com.guardian.search.domain;

import java.util.Objects;
import java.util.UUID;

/**
 * One record global search found.
 *
 * <p>Structured, never pre-formatted: the console composes "Driver · Greenwood Main" from these
 * fields in the operator's language (BR-CFG-005). Which optional field carries what depends on
 * {@link #type} and is specified per type in {@code SEARCH_API.md}.
 *
 * @param title the record's name — a person's full name, a vehicle's display name, a school's name
 * @param matchedValue the value that matched: the name again, or the number or code typed
 * @param kind a type-specific classifier — staff type, role code, vehicle type, region profile
 * @param code a type-specific identifier — admission number, employee code, registration, code
 * @param relatedStudentId for a guardian, the linked child shown alongside them
 * @param organizationId the organization the record belongs to — set only by the platform-wide
 *     search (ADR-0018), where results span organizations
 */
public record SearchHit(
    SearchResultType type,
    UUID id,
    String title,
    MatchedField matchedField,
    String matchedValue,
    String kind,
    String code,
    String status,
    UUID schoolId,
    String schoolName,
    UUID relatedStudentId,
    String relatedStudentName,
    UUID organizationId,
    String organizationName) {

  public SearchHit {
    Objects.requireNonNull(type, "type");
    Objects.requireNonNull(id, "id");
    Objects.requireNonNull(title, "title");
    Objects.requireNonNull(matchedField, "matchedField");
    Objects.requireNonNull(matchedValue, "matchedValue");
  }
}
