package com.guardian.search.application.result;

import java.util.List;
import java.util.Objects;

/**
 * Everything one search found, grouped by kind in display order. Kinds the caller may not see, and
 * kinds with no matches, are absent rather than empty.
 */
public record SearchResults(String query, List<SearchGroup> groups) {

  public SearchResults {
    Objects.requireNonNull(query, "query");
    groups = List.copyOf(groups);
  }
}
