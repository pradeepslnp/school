package com.guardian.common.audit;

import com.guardian.common.tenant.TenantId;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * A read of one child's personal data by someone who is not their guardian (BR-IAM-012 🔴).
 *
 * <p>Separate from {@link AuditRecord}, which records <em>changes</em>. This records
 * <em>looking</em> — the question a parent is entitled to ask is "who has been reading my child's
 * information?", and a change log cannot answer it.
 *
 * <p>Guardians reading their own children are not recorded. A parent looking at their own child is
 * the system working, and recording it would bury the accesses that warrant review under thousands
 * that never do.
 *
 * <p><strong>Every record names one student.</strong> {@code data_access_records.student_id} is
 * {@code NOT NULL} and {@code idx_data_access_student} leads with it, because the query this table
 * exists to answer is per-child. A listing therefore produces one record per student listed rather
 * than a single summary row — a summary would record that someone read <em>a</em> register while
 * leaving "who read Aarav's data?" unanswerable, which is the one question BR-IAM-012 is for.
 * {@link #recordCount} carries the size of the batch the row belonged to.
 */
public record DataAccessRecord(
    TenantId tenantId,
    UUID actorId,
    String actorRole,
    UUID studentId,
    AccessType accessType,
    String purpose,
    Integer recordCount,
    UUID correlationId,
    Instant occurredAt) {

  /** Matches {@code ck_data_access_type} on the table. */
  public enum AccessType {
    /** One student's record was opened. */
    VIEW,
    /** The student appeared in a listing; {@code recordCount} is the size of that listing. */
    LIST,
    /** Data left the platform (BR-RPT-002). */
    EXPORT,
    /** A report rendered the student's data. */
    REPORT
  }

  public DataAccessRecord {
    Objects.requireNonNull(tenantId, "tenantId");
    Objects.requireNonNull(actorId, "actorId");
    Objects.requireNonNull(actorRole, "actorRole");
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(accessType, "accessType");
    occurredAt = occurredAt == null ? Instant.now() : occurredAt;
  }

  /** One student's record was opened. */
  public static DataAccessRecord view(
      TenantId tenantId, UUID actorId, String actorRole, UUID studentId, String purpose) {
    return new DataAccessRecord(
        tenantId, actorId, actorRole, studentId, AccessType.VIEW, purpose, null, null, null);
  }

  /** One student who appeared in a listing of {@code recordCount} rows. */
  public static DataAccessRecord listed(
      TenantId tenantId,
      UUID actorId,
      String actorRole,
      UUID studentId,
      int recordCount,
      String purpose) {
    return new DataAccessRecord(
        tenantId, actorId, actorRole, studentId, AccessType.LIST, purpose, recordCount, null, null);
  }
}
