package com.guardian.search.application.result;

import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchResultType;
import java.util.List;
import java.util.Objects;

/**
 * The results of one kind, capped for display.
 *
 * @param hasMore whether more records of this kind matched than are shown — the console asks the
 *     operator to keep typing rather than paging, because a longer query is the faster way to one
 *     record and every extra student shown is another access record (BR-IAM-012)
 */
public record SearchGroup(SearchResultType type, List<SearchHit> hits, boolean hasMore) {

  public SearchGroup {
    Objects.requireNonNull(type, "type");
    hits = List.copyOf(hits);
  }
}
