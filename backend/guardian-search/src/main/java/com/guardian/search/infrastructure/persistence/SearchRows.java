package com.guardian.search.infrastructure.persistence;

import com.guardian.search.domain.MatchedField;
import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchQuery;
import com.guardian.search.domain.SearchResultType;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

/**
 * Turns search rows into {@link SearchHit}s — shared by the tenant-scoped projection ({@link
 * JdbcSearchReadModel}) and the platform-wide one ({@link JdbcPlatformSearchReadModel}), so a
 * record reads the same whichever path found it.
 *
 * <p>Which field matched is decided here, after the row is read, with the comparisons {@link
 * SearchQuery} defines. The SQL only answers "does anything match"; the console still learns what
 * did. Platform rows also carry the organization each record belongs to.
 */
final class SearchRows {

  private SearchRows() {}

  static RowMapper<SearchHit> students(SearchQuery query, boolean withOrganization) {
    return (rs, row) -> {
      String name = fullName(rs);
      String admissionNo = rs.getString("admission_no");
      Match match = match(query, name, text(MatchedField.ADMISSION_NO, admissionNo));
      return new SearchHit(
          SearchResultType.STUDENT,
          uuid(rs, "id"),
          name,
          match.field(),
          match.value(),
          null,
          admissionNo,
          rs.getString("enrolment_status"),
          uuid(rs, "school_id"),
          rs.getString("school_name"),
          null,
          null,
          organizationId(rs, withOrganization),
          organizationName(rs, withOrganization));
    };
  }

  static RowMapper<SearchHit> guardians(SearchQuery query, boolean withOrganization) {
    return (rs, row) -> {
      String name = fullName(rs);
      Match match =
          match(
              query,
              name,
              number(MatchedField.PHONE, rs.getString("phone")),
              text(MatchedField.EMAIL, rs.getString("email")));
      return new SearchHit(
          SearchResultType.GUARDIAN,
          uuid(rs, "id"),
          name,
          match.field(),
          match.value(),
          null,
          null,
          activeStatus(rs),
          uuid(rs, "school_id"),
          rs.getString("school_name"),
          uuid(rs, "student_id"),
          rs.getString("student_name"),
          organizationId(rs, withOrganization),
          organizationName(rs, withOrganization));
    };
  }

  static RowMapper<SearchHit> staff(SearchQuery query, boolean withOrganization) {
    return (rs, row) -> {
      String name = fullName(rs);
      String employeeCode = rs.getString("employee_code");
      Match match =
          match(
              query,
              name,
              number(MatchedField.PHONE, rs.getString("phone")),
              text(MatchedField.EMPLOYEE_CODE, employeeCode));
      return new SearchHit(
          SearchResultType.STAFF,
          uuid(rs, "id"),
          name,
          match.field(),
          match.value(),
          rs.getString("staff_type"),
          employeeCode,
          activeStatus(rs),
          uuid(rs, "school_id"),
          rs.getString("school_name"),
          null,
          null,
          organizationId(rs, withOrganization),
          organizationName(rs, withOrganization));
    };
  }

  static RowMapper<SearchHit> vehicles(SearchQuery query, boolean withOrganization) {
    return (rs, row) -> {
      String name = rs.getString("display_name");
      String registrationNo = rs.getString("registration_no");
      Match match = match(query, name, alphanumeric(MatchedField.REGISTRATION_NO, registrationNo));
      return new SearchHit(
          SearchResultType.VEHICLE,
          uuid(rs, "id"),
          name,
          match.field(),
          match.value(),
          rs.getString("vehicle_type"),
          registrationNo,
          rs.getString("status"),
          uuid(rs, "school_id"),
          rs.getString("school_name"),
          null,
          null,
          organizationId(rs, withOrganization),
          organizationName(rs, withOrganization));
    };
  }

  static RowMapper<SearchHit> routes(SearchQuery query, boolean withOrganization) {
    return (rs, row) -> {
      String name = rs.getString("name");
      String code = rs.getString("code");
      Match match = match(query, name, text(MatchedField.CODE, code));
      return new SearchHit(
          SearchResultType.ROUTE,
          uuid(rs, "id"),
          name,
          match.field(),
          match.value(),
          null,
          code,
          null,
          uuid(rs, "school_id"),
          rs.getString("school_name"),
          null,
          null,
          organizationId(rs, withOrganization),
          organizationName(rs, withOrganization));
    };
  }

  static RowMapper<SearchHit> schools(SearchQuery query, boolean withOrganization) {
    return (rs, row) -> {
      String name = rs.getString("name");
      String code = rs.getString("code");
      UUID id = uuid(rs, "id");
      Match match = match(query, name, text(MatchedField.CODE, code));
      return new SearchHit(
          SearchResultType.SCHOOL,
          id,
          name,
          match.field(),
          match.value(),
          null,
          code,
          rs.getString("status"),
          id,
          name,
          null,
          null,
          organizationId(rs, withOrganization),
          organizationName(rs, withOrganization));
    };
  }

  static RowMapper<SearchHit> administrativeUsers(SearchQuery query, boolean withOrganization) {
    return (rs, row) -> {
      String name = fullName(rs);
      Match match =
          match(
              query,
              name,
              text(MatchedField.EMAIL, rs.getString("email")),
              number(MatchedField.PHONE, rs.getString("phone")));
      return new SearchHit(
          SearchResultType.USER,
          uuid(rs, "id"),
          name,
          match.field(),
          match.value(),
          rs.getString("role_code"),
          null,
          rs.getString("status"),
          uuid(rs, "school_id"),
          rs.getString("school_name"),
          null,
          null,
          organizationId(rs, withOrganization),
          organizationName(rs, withOrganization));
    };
  }

  static RowMapper<SearchHit> organizations(SearchQuery query) {
    return (rs, row) -> {
      String name = rs.getString("name");
      String code = rs.getString("code");
      Match match = match(query, name, text(MatchedField.CODE, code));
      return new SearchHit(
          SearchResultType.ORGANIZATION,
          uuid(rs, "id"),
          name,
          match.field(),
          match.value(),
          rs.getString("region_profile_code"),
          code,
          rs.getString("status"),
          null,
          null,
          null,
          null,
          null,
          null);
    };
  }

  /**
   * Runs {@code sql} with positional {@code parameters}. A {@code Set} binds as a {@code uuid[]} —
   * the school scope — and null binds as a typed SQL null, which the digit comparisons turn into a
   * pattern that matches nothing.
   */
  static List<SearchHit> query(
      JdbcTemplate jdbc, String sql, RowMapper<SearchHit> mapper, Object... parameters) {
    return jdbc.query(
        connection -> {
          PreparedStatement statement = connection.prepareStatement(sql);
          for (int index = 0; index < parameters.length; index++) {
            Object value = parameters[index];
            if (value instanceof Set<?> ids) {
              statement.setArray(index + 1, connection.createArrayOf("uuid", ids.toArray()));
            } else if (value == null) {
              statement.setNull(index + 1, Types.VARCHAR);
            } else {
              statement.setObject(index + 1, value);
            }
          }
          return statement;
        },
        mapper);
  }

  private enum Comparison {
    TEXT,
    DIGITS,
    ALPHANUMERIC
  }

  private record Candidate(MatchedField field, String value, Comparison comparison) {}

  private record Match(MatchedField field, String value) {}

  private static Candidate text(MatchedField field, String value) {
    return new Candidate(field, value, Comparison.TEXT);
  }

  private static Candidate number(MatchedField field, String value) {
    return new Candidate(field, value, Comparison.DIGITS);
  }

  private static Candidate alphanumeric(MatchedField field, String value) {
    return new Candidate(field, value, Comparison.ALPHANUMERIC);
  }

  /**
   * Which field matched, preferring the name. The WHERE clause has already established that one
   * did; this only names it.
   */
  private static Match match(SearchQuery query, String name, Candidate... candidates) {
    if (query.matchesText(name)) {
      return new Match(MatchedField.NAME, name);
    }
    for (Candidate candidate : candidates) {
      String value = candidate.value();
      boolean matched =
          switch (candidate.comparison()) {
            case TEXT -> query.matchesText(value);
            case DIGITS -> query.matchesDigits(value);
            case ALPHANUMERIC -> query.matchesText(value) || query.matchesAlphanumeric(value);
          };
      if (matched) {
        return new Match(candidate.field(), value);
      }
    }
    return new Match(MatchedField.NAME, name);
  }

  private static String fullName(ResultSet rs) throws SQLException {
    return (rs.getString("first_name") + " " + rs.getString("last_name")).strip();
  }

  private static String activeStatus(ResultSet rs) throws SQLException {
    return rs.getBoolean("is_active") ? "ACTIVE" : "INACTIVE";
  }

  private static UUID organizationId(ResultSet rs, boolean withOrganization) throws SQLException {
    return withOrganization ? uuid(rs, "organization_id") : null;
  }

  private static String organizationName(ResultSet rs, boolean withOrganization)
      throws SQLException {
    return withOrganization ? rs.getString("organization_name") : null;
  }

  private static UUID uuid(ResultSet rs, String column) throws SQLException {
    return rs.getObject(column, UUID.class);
  }
}
