package com.guardian.infrastructure.audit;

import com.guardian.common.audit.DataAccessPort;
import com.guardian.common.audit.DataAccessRecord;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Writes data-access records (BR-IAM-012 🔴).
 *
 * <p>{@link Propagation#MANDATORY} for the same reason {@code JdbcAuditAdapter} uses it: the record
 * must not commit independently of the read it describes, nor the read succeed without it. A
 * best-effort access log is one that is empty exactly when someone took care to make it so.
 *
 * <p>Plain JDBC rather than JPA because the table is append-only — a BEFORE UPDATE OR DELETE
 * trigger enforces that even for the owner — so there is no entity lifecycle to model.
 */
@Component
class JdbcDataAccessAdapter implements DataAccessPort {

  private static final String INSERT_SQL =
      """
      INSERT INTO data_access_records (
          id, tenant_id, actor_id, actor_role, student_id,
          access_type, purpose, record_count, correlation_id, occurred_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      """;

  private final JdbcTemplate jdbcTemplate;

  JdbcDataAccessAdapter(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  @Transactional(propagation = Propagation.MANDATORY)
  public void record(DataAccessRecord record) {
    jdbcTemplate.update(INSERT_SQL, argumentsOf(record), TYPES);
  }

  @Override
  @Transactional(propagation = Propagation.MANDATORY)
  public void recordAll(List<DataAccessRecord> records) {
    if (records.isEmpty()) {
      return;
    }
    jdbcTemplate.batchUpdate(INSERT_SQL, records.stream().map(this::argumentsOf).toList(), TYPES);
  }

  private static final int[] TYPES = {
    Types.OTHER, // id
    Types.OTHER, // tenant_id
    Types.OTHER, // actor_id
    Types.VARCHAR, // actor_role
    Types.OTHER, // student_id
    Types.VARCHAR, // access_type
    Types.VARCHAR, // purpose
    Types.INTEGER, // record_count
    Types.OTHER, // correlation_id
    Types.TIMESTAMP // occurred_at
  };

  private Object[] argumentsOf(DataAccessRecord record) {
    return new Object[] {
      UUID.randomUUID(),
      record.tenantId().value(),
      record.actorId(),
      record.actorRole(),
      record.studentId(),
      record.accessType().name(),
      record.purpose(),
      record.recordCount(),
      record.correlationId(),
      Timestamp.from(record.occurredAt())
    };
  }
}
