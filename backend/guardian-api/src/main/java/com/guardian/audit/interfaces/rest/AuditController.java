package com.guardian.audit.interfaces.rest;

import com.guardian.audit.application.AuditQuery;
import com.guardian.audit.application.ListAuditRecordsUseCase;
import com.guardian.audit.interfaces.rest.dto.AuditRecordResponse;
import com.guardian.common.security.RequiresPermission;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * The audit trail (AUD-002, screen A-54) and the override register (AUD-003, screen A-55). See
 * guardian-docs/04-api/REPORTING_AUDIT_CONFIG_API.md §Audit.
 *
 * <p><strong>Read-only, and that is a control.</strong> There is deliberately no {@code POST},
 * {@code PATCH}, or {@code DELETE} here: audit records are written only in the same transaction as
 * the change they describe (BR-AUD-002 🔴), so the absence of any mutation endpoint is what
 * guarantees a record cannot be forged or erased through the API.
 *
 * <p>Both reads require {@code PERM-AUDIT-VIEW} and are confined to the caller's tenant by
 * row-level security. A platform operator's cross-tenant view is a separate endpoint (AUD-004), not
 * a wider mode of this one.
 */
@RestController
@RequestMapping("/api/v1/audit-records")
public class AuditController {

  private final ListAuditRecordsUseCase listAuditRecords;

  public AuditController(ListAuditRecordsUseCase listAuditRecords) {
    this.listAuditRecords = listAuditRecords;
  }

  @GetMapping
  @RequiresPermission("PERM-AUDIT-VIEW")
  public List<AuditRecordResponse> list(
      @RequestParam(required = false) String action,
      @RequestParam(required = false) UUID actorId,
      @RequestParam(required = false) String subjectType,
      @RequestParam(required = false, defaultValue = "100") int limit) {

    return listAuditRecords
        .execute(new AuditQuery(action, actorId, subjectType, false, limit))
        .stream()
        .map(AuditRecordResponse::from)
        .toList();
  }

  /** The override register (AUD-003): only actions carrying a reason — every one answerable. */
  @GetMapping("/overrides")
  @RequiresPermission("PERM-AUDIT-VIEW")
  public List<AuditRecordResponse> overrides(
      @RequestParam(required = false, defaultValue = "100") int limit) {

    return listAuditRecords
        .execute(new AuditQuery(null, null, null, true, limit))
        .stream()
        .map(AuditRecordResponse::from)
        .toList();
  }
}
