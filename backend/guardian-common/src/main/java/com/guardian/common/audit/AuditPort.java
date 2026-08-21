package com.guardian.common.audit;

/**
 * Writes audit records. Implemented in infrastructure; called from use cases.
 *
 * <p>The implementation <strong>must</strong> participate in the caller's transaction (BR-AUD-002).
 * If the audit write fails, the business change rolls back — the platform refuses an operation
 * rather than performing it unrecorded.
 *
 * <p>That guarantee is a large part of why this platform is a modular monolith over a shared
 * database: across service boundaries it would require a distributed transaction, or be quietly
 * abandoned. See guardian-docs/02-system-design/AUDIT_AND_LOGGING.md.
 */
public interface AuditPort {

  void record(AuditRecord auditRecord);
}
