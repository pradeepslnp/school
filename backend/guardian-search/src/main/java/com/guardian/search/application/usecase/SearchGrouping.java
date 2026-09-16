package com.guardian.search.application.usecase;

import com.guardian.search.application.result.SearchGroup;
import com.guardian.search.domain.MatchedField;
import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchQuery;
import com.guardian.search.domain.SearchResultType;
import com.guardian.tenancy.application.usecase.ListOrganizationsUseCase;
import java.util.List;

/** What the tenant-scoped and platform-wide searches share: the per-kind cap, and organizations. */
final class SearchGrouping {

  /** Results shown per kind. Small on purpose: a longer query beats a longer list. */
  static final int RESULTS_PER_TYPE = 5;

  /** One more than is shown, to learn whether there are more. */
  static final int FETCH_SIZE = RESULTS_PER_TYPE + 1;

  private SearchGrouping() {}

  /** Adds a group capped to {@link #RESULTS_PER_TYPE}. Kinds with no matches are left out. */
  static void add(List<SearchGroup> groups, SearchResultType type, List<SearchHit> fetched) {
    if (fetched.isEmpty()) {
      return;
    }
    boolean hasMore = fetched.size() > RESULTS_PER_TYPE;
    groups.add(
        new SearchGroup(type, hasMore ? fetched.subList(0, RESULTS_PER_TYPE) : fetched, hasMore));
  }

  /**
   * Every organization whose name or code matches, through {@link ListOrganizationsUseCase} — the
   * single gated entry to the cross-tenant organization list (BR-TEN-004) — rather than a second
   * caller of its unfiltered database function. That use case refuses any role but {@code
   * SUPER_ADMIN}.
   */
  static List<SearchHit> platformOrganizations(
      ListOrganizationsUseCase listOrganizations, SearchQuery query, String actorRole, int limit) {
    return listOrganizations.execute(actorRole).stream()
        .filter(
            organization ->
                query.matchesText(organization.name())
                    || query.matchesText(organization.code().value()))
        .limit(limit)
        .map(
            organization -> {
              boolean byName = query.matchesText(organization.name());
              String code = organization.code().value();
              return new SearchHit(
                  SearchResultType.ORGANIZATION,
                  organization.id().value(),
                  organization.name(),
                  byName ? MatchedField.NAME : MatchedField.CODE,
                  byName ? organization.name() : code,
                  organization.regionProfileCode(),
                  code,
                  organization.status().name(),
                  null,
                  null,
                  null,
                  null,
                  null,
                  null);
            })
        .toList();
  }
}
