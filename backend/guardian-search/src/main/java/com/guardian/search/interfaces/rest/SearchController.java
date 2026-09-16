package com.guardian.search.interfaces.rest;

import com.guardian.common.security.CallerAccess;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.search.application.result.SearchResults;
import com.guardian.search.application.usecase.RunGlobalSearchUseCase;
import com.guardian.search.application.usecase.RunPlatformSearchUseCase;
import com.guardian.search.domain.SearchQuery;
import com.guardian.search.interfaces.rest.dto.SearchResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * The console's global search — feature SRC-001. See guardian-docs/04-api/SEARCH_API.md.
 *
 * <p>{@code PERM-SEARCH-QUERY} opens the endpoint; what it may return is decided per kind of record
 * from {@link CallerAccess}, which is resolved server-side and cannot be influenced by anything in
 * the request. The only input taken from the client is the query text.
 *
 * <p>This layer only translates, plus one routing choice made from that server-resolved scope: a
 * platform operator's search spans every organization ({@link RunPlatformSearchUseCase}, ADR-0018);
 * everyone else searches the organization their request acts in, under row-level security ({@link
 * RunGlobalSearchUseCase}, ADR-0017). The platform use case re-checks the scope itself rather than
 * trusting this branch.
 */
@RestController
@RequestMapping("/api/v1/search")
public class SearchController {

  private final RunGlobalSearchUseCase runGlobalSearch;
  private final RunPlatformSearchUseCase runPlatformSearch;

  public SearchController(
      RunGlobalSearchUseCase runGlobalSearch, RunPlatformSearchUseCase runPlatformSearch) {
    this.runGlobalSearch = runGlobalSearch;
    this.runPlatformSearch = runPlatformSearch;
  }

  /**
   * {@code q} is optional at the binding layer on purpose: a missing query is refused by {@link
   * SearchQuery#of} with the documented validation error rather than surfacing as a framework
   * binding failure.
   */
  @GetMapping
  @RequiresPermission("PERM-SEARCH-QUERY")
  public SearchResponse search(
      @RequestParam(name = "q", required = false) String q,
      CallerAccess access,
      CurrentActor actor) {
    SearchQuery query = SearchQuery.of(q);
    SearchResults results =
        access.scope().platformWide()
            ? runPlatformSearch.execute(query, access, actor)
            : runGlobalSearch.execute(query, access, actor);
    return SearchResponse.from(results);
  }
}
