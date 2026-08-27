package com.guardian.audit.application;

import com.guardian.audit.domain.AuditEntry;
import java.util.List;

/**
 * Read access to the audit trail (AUD-002).
 *
 * <p>Read-only by design and by grant: {@code guardian_app} holds only {@code SELECT, INSERT} on
 * {@code audit_records} — there is no update or delete path anywhere, which is the point of an
 * append-only evidence table (BR-AUD-002). This port exposes only a query; nothing here can alter a
 * record.
 *
 * <p>Implicitly tenant-scoped by row-level security (ADR-0001), so no method takes a tenant
 * argument.
 */
public interface AuditQueryPort {

  /** Matching records, most recent first, capped at {@link AuditQuery#limit()}. */
  List<AuditEntry> find(AuditQuery query);
}
