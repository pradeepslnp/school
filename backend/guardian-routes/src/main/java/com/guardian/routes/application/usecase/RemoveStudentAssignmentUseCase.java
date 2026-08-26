package com.guardian.routes.application.usecase;

import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantContext;
import com.guardian.routes.application.port.RouteStudentAssignmentRepository;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Removes a student's route assignment (feature RTE-003).
 *
 * <p>Deactivates rather than deletes — a trip that already ran must still be able to show who was
 * expected that day, so the row survives with {@code is_active = false} and a {@code valid_to} of
 * today. Audited, because a child no longer being on a bus is exactly the kind of change someone
 * may later need to account for.
 */
@Service
public class RemoveStudentAssignmentUseCase {

  private final RouteStudentAssignmentRepository assignments;
  private final AuditPort auditPort;

  public RemoveStudentAssignmentUseCase(
      RouteStudentAssignmentRepository assignments, AuditPort auditPort) {
    this.assignments = assignments;
    this.auditPort = auditPort;
  }

  @Transactional
  public void execute(UUID assignmentId, UUID actorUserId, String actorRole) {
    assignments.deactivate(assignmentId, actorUserId);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorUserId, AuditRecord.ActorType.USER, actorRole)
            .action("STUDENT_ASSIGNMENT_REMOVED")
            .subject("RouteStudentAssignment", assignmentId)
            .after(Map.of("assignmentId", assignmentId.toString()))
            .build());
  }
}
