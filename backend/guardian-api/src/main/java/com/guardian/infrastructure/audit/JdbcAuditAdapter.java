package com.guardian.infrastructure.audit;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import java.sql.Types;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Writes audit records.
 *
 * <p>{@link Propagation#MANDATORY} is the important detail. It forces this write to join an
 * existing transaction and throws if there is none — so an audit record can never be committed
 * independently of the change it describes, and a change can never commit without its audit record
 * (BR-AUD-002).
 *
 * <p>The alternative, {@code REQUIRES_NEW}, is the usual instinct and is wrong here: it would let a
 * business change roll back while its audit record survived, or vice versa. In a system whose
 * records are evidence after an incident, an audit trail that disagrees with reality is worse than
 * no audit trail.
 *
 * <p>Plain JDBC rather than JPA because the table is append-only and has no domain model: there is
 * nothing to map, and an entity would imply an update path that does not exist.
 */
@Component
class JdbcAuditAdapter implements AuditPort {

  private static final String INSERT_SQL =
      """
      INSERT INTO audit_records (
          id, tenant_id, actor_id, actor_type, actor_role, action,
          subject_type, subject_id, reason, source, correlation_id,
          before_values, after_values, occurred_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb, ?::jsonb, ?)
      """;

  private final JdbcTemplate jdbcTemplate;
  private final ObjectMapper objectMapper;

  JdbcAuditAdapter(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
    this.jdbcTemplate = jdbcTemplate;
    this.objectMapper = objectMapper;
  }

  @Override
  @Transactional(propagation = Propagation.MANDATORY)
  public void record(AuditRecord auditRecord) {
    jdbcTemplate.update(
        INSERT_SQL,
        UUID.randomUUID(),
        auditRecord.tenantId().value(),
        auditRecord.actorId(),
        auditRecord.actorType().name(),
        auditRecord.actorRole(),
        auditRecord.action(),
        auditRecord.subjectType(),
        auditRecord.subjectId(),
        auditRecord.reason(),
        auditRecord.source().name(),
        auditRecord.correlationId(),
        toJson(auditRecord.beforeValues()),
        toJson(auditRecord.afterValues()),
        java.sql.Timestamp.from(auditRecord.occurredAt()));
  }

  private String toJson(Map<String, Object> values) {
    if (values == null || values.isEmpty()) {
      return null;
    }
    try {
      return objectMapper.writeValueAsString(values);
    } catch (JsonProcessingException e) {
      // Failing loudly is correct: a change must not commit with an unrecorded audit trail.
      throw new IllegalStateException("Could not serialise audit values", e);
    }
  }

  @SuppressWarnings("unused")
  private static final int JSONB_TYPE = Types.OTHER;
}
