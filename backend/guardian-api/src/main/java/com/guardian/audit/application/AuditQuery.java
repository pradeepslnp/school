package com.guardian.audit.application;

import java.util.UUID;

/**
 * The filters a caller may apply to the audit trail (AUD-002/AUD-003).
 *
 * <p>All filters are optional and combine with AND. {@code overridesOnly} narrows the trail to
 * actions that carry a reason — the override register (AUD-003, A-55), which the {@code
 * idx_audit_action ... WHERE reason IS NOT NULL} index serves directly. {@code limit} is clamped to
 * a sane window here so a caller cannot ask for an unbounded scan of an append-only table that only
 * grows.
 */
public record AuditQuery(
    String action, UUID actorId, String subjectType, boolean overridesOnly, int limit) {

  private static final int DEFAULT_LIMIT = 100;
  private static final int MAX_LIMIT = 500;

  public AuditQuery {
    if (limit <= 0 || limit > MAX_LIMIT) {
      limit = limit <= 0 ? DEFAULT_LIMIT : MAX_LIMIT;
    }
    action = blankToNull(action);
    subjectType = blankToNull(subjectType);
  }

  private static String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }
}
