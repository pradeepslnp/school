package com.guardian.audit.application;

import com.guardian.audit.domain.AuditEntry;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lists audit records for the audit trail and override register (AUD-002, AUD-003; screens A-54,
 * A-55).
 *
 * <p>A read, and only a read — the whole module exposes no way to write or change an audit record,
 * because they are written only in the same transaction as the change they describe (BR-AUD-002).
 * Runs under the caller's tenant context, so row-level security confines the result to their own
 * tenant; a platform operator's cross-tenant view is a separate, more heavily gated endpoint.
 */
@Service
public class ListAuditRecordsUseCase {

  private final AuditQueryPort auditQuery;

  public ListAuditRecordsUseCase(AuditQueryPort auditQuery) {
    this.auditQuery = auditQuery;
  }

  @Transactional(readOnly = true)
  public List<AuditEntry> execute(AuditQuery query) {
    return auditQuery.find(query);
  }
}
