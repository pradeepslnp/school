package com.guardian.infrastructure.audit;

import com.guardian.audit.application.AuditQuery;
import com.guardian.audit.application.AuditQueryPort;
import com.guardian.audit.domain.AuditEntry;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * Reads {@code audit_records} for the audit trail (AUD-002, AUD-003).
 *
 * <p>Plain JDBC, alongside the write adapter {@code JdbcAuditAdapter}: the table is append-only and
 * has no domain aggregate, so there is nothing for JPA to map. Runs under row-level security, so no
 * tenant predicate appears in the SQL — repeating it would imply the policy were optional.
 *
 * <p>The {@code WHERE} is assembled from only the filters that were supplied, each as a bound
 * parameter — never string-concatenated values — so the dynamic query cannot become an injection
 * surface. Ordering is {@code occurred_at DESC, id DESC}, served by the table's own indexes.
 */
@Component
class JdbcAuditQueryRepository implements AuditQueryPort {

  private final JdbcTemplate jdbcTemplate;

  JdbcAuditQueryRepository(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  public List<AuditEntry> find(AuditQuery query) {
    StringBuilder sql =
        new StringBuilder(
            """
            SELECT id, actor_id, actor_type, actor_role, action,
                   subject_type, subject_id, reason, source, occurred_at
            FROM audit_records
            WHERE 1 = 1
            """);
    List<Object> args = new ArrayList<>();

    if (query.action() != null) {
      sql.append(" AND action = ?");
      args.add(query.action());
    }
    if (query.actorId() != null) {
      sql.append(" AND actor_id = ?");
      args.add(query.actorId());
    }
    if (query.subjectType() != null) {
      sql.append(" AND subject_type = ?");
      args.add(query.subjectType());
    }
    if (query.overridesOnly()) {
      sql.append(" AND reason IS NOT NULL");
    }

    sql.append(" ORDER BY occurred_at DESC, id DESC LIMIT ?");
    args.add(query.limit());

    return jdbcTemplate.query(sql.toString(), MAPPER, args.toArray());
  }

  private static final RowMapper<AuditEntry> MAPPER =
      (ResultSet rs, int rowNum) -> {
        Timestamp occurredAt = rs.getTimestamp("occurred_at");
        return new AuditEntry(
            rs.getObject("id", UUID.class),
            rs.getObject("actor_id", UUID.class),
            rs.getString("actor_type"),
            rs.getString("actor_role"),
            rs.getString("action"),
            rs.getString("subject_type"),
            rs.getObject("subject_id", UUID.class),
            rs.getString("reason"),
            rs.getString("source"),
            occurredAt == null ? null : occurredAt.toInstant());
      };
}
