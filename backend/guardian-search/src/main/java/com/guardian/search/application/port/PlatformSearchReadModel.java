package com.guardian.search.application.port;

import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchQuery;
import java.util.List;

/**
 * The platform-wide search read (ADR-0018): the same kinds of record as {@link SearchReadModel},
 * across every organization at once, each result naming the organization it belongs to.
 *
 * <p><strong>This port crosses tenants.</strong> Its adapter calls {@code SECURITY DEFINER}
 * functions that bypass row-level security (V19__platform_search.sql), so nothing here narrows by
 * tenant or school. Its only caller, {@code RunPlatformSearchUseCase}, must establish that the
 * caller holds the platform scope before calling it, and must audit every organization whose
 * records it shows (BR-TEN-004, BR-AUD-005). A second caller needs its own ADR.
 *
 * <p>Each method returns at most {@code limit} rows (the functions cap at 26 regardless). Read-only
 * by construction.
 */
public interface PlatformSearchReadModel {

  List<SearchHit> students(SearchQuery query, int limit);

  List<SearchHit> guardians(SearchQuery query, int limit);

  List<SearchHit> staff(SearchQuery query, int limit);

  List<SearchHit> vehicles(SearchQuery query, int limit);

  List<SearchHit> routes(SearchQuery query, int limit);

  List<SearchHit> schools(SearchQuery query, int limit);

  List<SearchHit> administrativeUsers(SearchQuery query, int limit);
}
