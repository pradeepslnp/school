package com.guardian.search.interfaces.rest.dto;

import com.guardian.search.application.result.SearchGroup;
import com.guardian.search.application.result.SearchResults;
import com.guardian.search.domain.SearchHit;
import java.util.List;
import java.util.UUID;

/**
 * Wire representation of a global search, matching guardian-docs/04-api/SEARCH_API.md.
 *
 * <p>Carries no display text: the console composes titles and subtitles from these fields in the
 * operator's language (BR-CFG-005).
 */
public record SearchResponse(String query, List<GroupResponse> groups) {

  public record GroupResponse(String type, List<HitResponse> results, boolean hasMore) {

    static GroupResponse from(SearchGroup group) {
      return new GroupResponse(
          group.type().name(),
          group.hits().stream().map(HitResponse::from).toList(),
          group.hasMore());
    }
  }

  /**
   * @param organizationId set only on a platform-wide search (ADR-0018), naming the organization
   *     the record belongs to
   */
  public record HitResponse(
      String type,
      UUID id,
      String title,
      String matchedField,
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

    static HitResponse from(SearchHit hit) {
      return new HitResponse(
          hit.type().name(),
          hit.id(),
          hit.title(),
          hit.matchedField().name(),
          hit.matchedValue(),
          hit.kind(),
          hit.code(),
          hit.status(),
          hit.schoolId(),
          hit.schoolName(),
          hit.relatedStudentId(),
          hit.relatedStudentName(),
          hit.organizationId(),
          hit.organizationName());
    }
  }

  public static SearchResponse from(SearchResults results) {
    return new SearchResponse(
        results.query(), results.groups().stream().map(GroupResponse::from).toList());
  }
}
