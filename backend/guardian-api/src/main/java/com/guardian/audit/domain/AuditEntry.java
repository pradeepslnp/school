package com.guardian.audit.domain;

import java.time.Instant;
import java.util.UUID;

/**
 * A read projection of one {@code audit_records} row for the audit trail screen (AUD-002, A-54).
 *
 * <p>Deliberately not the write-side {@code AuditRecord}: this carries only what the trail lists,
 * and omits {@code before_values}/{@code after_values} — the full before/after diff belongs to a
 * per-record detail view, not a scrollable list, and pulling two JSONB blobs per row into every
 * page would be a cost the list never spends.
 *
 * <p>Reads run under row-level security, so an {@code AuditEntry} only ever describes an action in
 * the caller's own tenant. Cross-tenant platform operations are a separate, more heavily gated read
 * (AUD-004, {@code /audit-records/platform-access}).
 */
public record AuditEntry(
    UUID id,
    UUID actorId,
    String actorType,
    String actorRole,
    String action,
    String subjectType,
    UUID subjectId,
    String reason,
    String source,
    Instant occurredAt) {}
