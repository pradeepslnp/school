package com.guardian.parent.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.DataAccessPort;
import com.guardian.common.audit.DataAccessRecord;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.security.AccessScope;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.tenant.TenantContext;
import com.guardian.parent.application.port.StudentTransportReadModel;
import com.guardian.parent.application.result.StudentTransportView;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The bus and crew a student is assigned to, for the student record (feature STU-009, screen A-11,
 * ADR-0020).
 *
 * <p>A child's route and stop say where they are collected every day, so reading them is an access
 * to child personal data: it is recorded (BR-IAM-012 🔴), in the same transaction, as {@code
 * GetStudentUseCase} does — a read whose access record cannot be stored does not happen. That
 * record is this module's only write, and it goes through the audit port, never to a table this
 * module reads.
 *
 * <p>A student outside the caller's school scope answers {@code 404 STUDENT_NOT_FOUND}, the same as
 * one that does not exist (BR-IAM-006).
 */
@Service
@BusinessRule({"BR-IAM-012", "BR-IAM-006"})
public class GetStudentTransportUseCase {

  private static final String PURPOSE = "STUDENT_TRANSPORT";

  private final StudentTransportReadModel readModel;
  private final DataAccessPort dataAccessPort;

  public GetStudentTransportUseCase(
      StudentTransportReadModel readModel, DataAccessPort dataAccessPort) {
    this.readModel = readModel;
    this.dataAccessPort = dataAccessPort;
  }

  @Transactional
  public StudentTransportView execute(UUID studentId, AccessScope scope, CurrentActor actor) {
    StudentTransportView view =
        readModel
            .transportOf(studentId, scope)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        ErrorCode.STUDENT_NOT_FOUND, "Student", studentId));

    dataAccessPort.record(
        DataAccessRecord.view(
            TenantContext.require(), actor.userId(), actor.role(), studentId, PURPOSE));

    return view;
  }
}
