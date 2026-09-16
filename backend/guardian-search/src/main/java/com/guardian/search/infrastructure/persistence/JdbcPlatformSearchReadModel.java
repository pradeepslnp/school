package com.guardian.search.infrastructure.persistence;

import com.guardian.search.application.port.PlatformSearchReadModel;
import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchQuery;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * The platform-wide search projection (ADR-0018) — calls to the {@code platform_search_*} functions
 * V19__platform_search.sql defines, and nothing else.
 *
 * <p>The cross-tenant SQL itself lives in the migration, owned by {@code guardian_platform_ops}, so
 * the bypass of row-level security is a fixed, reviewable object in the schema rather than a query
 * string the application could change. This adapter can only choose the search text and the limit.
 */
@Component
public class JdbcPlatformSearchReadModel implements PlatformSearchReadModel {

  private final JdbcTemplate jdbc;

  public JdbcPlatformSearchReadModel(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public List<SearchHit> students(SearchQuery query, int limit) {
    return SearchRows.query(
        jdbc,
        "SELECT * FROM platform_search_students(?, ?, ?)",
        SearchRows.students(query, true),
        query.containsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> guardians(SearchQuery query, int limit) {
    return SearchRows.query(
        jdbc,
        "SELECT * FROM platform_search_guardians(?, ?, ?, ?)",
        SearchRows.guardians(query, true),
        query.containsPattern(),
        query.digitsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> staff(SearchQuery query, int limit) {
    return SearchRows.query(
        jdbc,
        "SELECT * FROM platform_search_staff(?, ?, ?, ?)",
        SearchRows.staff(query, true),
        query.containsPattern(),
        query.digitsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> vehicles(SearchQuery query, int limit) {
    return SearchRows.query(
        jdbc,
        "SELECT * FROM platform_search_vehicles(?, ?, ?, ?)",
        SearchRows.vehicles(query, true),
        query.containsPattern(),
        query.alphanumericPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> routes(SearchQuery query, int limit) {
    return SearchRows.query(
        jdbc,
        "SELECT * FROM platform_search_routes(?, ?, ?)",
        SearchRows.routes(query, true),
        query.containsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> schools(SearchQuery query, int limit) {
    return SearchRows.query(
        jdbc,
        "SELECT * FROM platform_search_schools(?, ?, ?)",
        SearchRows.schools(query, true),
        query.containsPattern(),
        query.prefixPattern(),
        limit);
  }

  @Override
  public List<SearchHit> administrativeUsers(SearchQuery query, int limit) {
    return SearchRows.query(
        jdbc,
        "SELECT * FROM platform_search_administrative_users(?, ?, ?, ?)",
        SearchRows.administrativeUsers(query, true),
        query.containsPattern(),
        query.digitsPattern(),
        query.prefixPattern(),
        limit);
  }
}
