package com.guardian.audit.interfaces.rest.dto;

import com.guardian.audit.domain.AuditEntry;
import java.time.Instant;
import java.util.UUID;

/**
 * One audit record as the trail reads it (AUD-002). Shape follows
 * guardian-docs/04-api/REPORTING_AUDIT_CONFIG_API.md §Audit.
 *
 * <p>No before/after diff here — the list shows what happened, when, by whom, and (for overrides)
 * why; the full value diff is a detail concern, not a list column.
 */
public record AuditRecordResponse(
    UUID id,
    UUID actorId,
    String actorType,
    String actorRole,
    String action,
    String subjectType,
    UUID subjectId,
    String reason,
    String source,
    Instant occurredAt) {

  public static AuditRecordResponse from(AuditEntry entry) {
    return new AuditRecordResponse(
        entry.id(),
        entry.actorId(),
        entry.actorType(),
        entry.actorRole(),
        entry.action(),
        entry.subjectType(),
        entry.subjectId(),
        entry.reason(),
        entry.source(),
        entry.occurredAt());
  }
}
